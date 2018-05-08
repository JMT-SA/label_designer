# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV', 'development'))

require 'pstore'
require 'net/http'
require 'uri'
require 'pry' if ENV.fetch('RACK_ENV') == 'development'

require './lib/types_for_dry'
require './lib/crossbeams_responses'
require './lib/base_repo'
require './lib/base_interactor'
require './lib/base_service'
require './lib/local_store' # Will only work for processes running from one dir.
require './lib/ui_rules'
require './lib/library_versions'
Dir['./helpers/**/*.rb'].each { |f| require f }
Dir['./lib/applets/*.rb'].each { |f| require f }

ENV['ROOT'] = File.dirname(__FILE__)
ENV['VERSION'] = File.read('VERSION')
LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')

Crossbeams::LabelDesigner::Config.configure do |config| # Set up configuration for label designer gem.
  # config.json_load_path = '/load_label'
  # config.json_save_path = '/save_label'
  # config.json_save_path = '/save_label'
end

module Crossbeams
  class FrameworkError < StandardError
  end

  class AuthorizationError < StandardError
  end
end

class LabelDesigner < Roda
  include CommonHelpers
  include ErrorHelpers
  include MenuHelpers

  use Rack::Session::Cookie, secret: 'some_nice_long_random_string_DSKJH4378EYR7EGKUFH', key: '_lbld_session'
  use Rack::MethodOverride # Use with all_verbs plugin to allow 'r.delete' etc.

  plugin :data_grid, path: File.dirname(__FILE__),
                     list_url: '/list/%s/grid',
                     list_nested_url: '/list/%s/nested_grid',
                     list_multi_url: '/list/%s/grid_multi',
                     search_url: '/search/%s/grid',
                     filter_url: '/search/%s',
                     run_search_url: '/search/%s/run',
                     run_to_excel_url: '/search/%s/xls'
  plugin :all_verbs
  plugin :render
  plugin :partials
  plugin :assets, css: 'style.scss', precompiled: 'prestyle.css', sri: nil # SRI: nil because integrity calculated incorrectly....
  plugin :public # serve assets from public folder.
  plugin :multi_route
  plugin :content_for, append: true
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true, skip_if: ->(_) { ENV['RACK_ENV'] == 'test' } # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
  plugin :json_parser
  plugin :rodauth do
    db DB
    enable :login, :logout # , :change_password
    logout_route 'a_dummy_route' # Override 'logout' route so that we have control over it.
    # logout_notice_flash 'Logged out'
    session_key :user_id
    login_param 'login_name'
    login_label 'Login name'
    login_column :login_name
    accounts_table :vw_active_users # Only active users can login.
    account_password_hash_column :password_hash
  end
  unless ENV['RACK_ENV'] == 'development' && ENV['NO_ERR_HANDLE']
    plugin :error_handler do |e|
      show_error(e, request.has_header?('HTTP_X_CUSTOM_REQUEST_TYPE'), @cbr_json_response)
      # = if prod and unexpected exception type, just display "something whent wrong" and log
      # = use an exception library & email...
    end
  end
  Dir['./routes/*.rb'].each { |f| require f }

  route do |r|
    initialize_route_instance_vars

    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    r.rodauth
    rodauth.require_authentication
    r.redirect('/login') if current_user.nil? # Session might have the incorrect user_id

    r.root do
      r.redirect('/list/labels')
    end

    r.multi_route

    r.on 'iframe', Integer do |id|
      repo = SecurityApp::MenuRepo.new
      pf = repo.find_program_function(id)
      view(inline: %(<iframe src="#{pf.url}" title="#{pf.program_function_name}" width="100%" style="height:80vh"></iframe>))
    end

    r.is 'logout' do
      rodauth.logout
      flash[:notice] = 'Logged out'
      r.redirect('/login')
    end

    r.is 'versions' do
      versions = LibraryVersions.new(:layout,
                                     :dataminer,
                                     :label_designer,
                                     :datagrid,
                                     :ag_grid,
                                     :selectr,
                                     :sortable,
                                     :konva,
                                     :lodash,
                                     :multi,
                                     :sweetalert)
      @layout = Crossbeams::Layout::Page.build do |page, _|
        page.section do |section|
          section.add_text('Gem and Javascript library versions', wrapper: :h2)
          section.add_table(versions.to_a, versions.columns, alignment: { version: :right })
        end
      end
      view('crossbeams_layout_page')
    end

    r.is 'not_found' do
      response.status = 404
      view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
    end

    r.on 'label_designer' do
      r.is do
        view(inline: label_designer_page(label_name: params[:label_name],
                                         label_dimension: params[:label_dimension],
                                         px_per_mm: params[:px_per_mm]))
      end
    end

    r.on 'save_label' do
      r.on :id do |id|
        r.post do
          repo = LabelApp::LabelRepo.new
          changeset = { label_json: params[:label],
                        variable_xml: params[:XMLString],
                        png_image: Sequel.blob(image_from_param(params[:imageString])) }
          repo.update_label(id, changeset)

          flash[:notice] = 'Updated'
          response['Content-Type'] = 'application/json'
          { redirect: session[:last_grid_url] }.to_json
        end
      end

      r.post do
        repo = LabelApp::LabelRepo.new
        extra_attributes = session[:new_label_attributes]
        changeset = { label_json: params[:label],
                      label_name: params[:labelName],
                      label_dimension: params[:labelDimension],
                      px_per_mm: params[:pixelPerMM],
                      container_type: extra_attributes[:container_type],
                      commodity: extra_attributes[:commodity],
                      market: extra_attributes[:market],
                      language: extra_attributes[:language],
                      category: extra_attributes[:category],
                      sub_category: extra_attributes[:sub_category],
                      variable_xml: params[:XMLString],
                      png_image: Sequel.blob(image_from_param(params[:imageString])) }
        repo.create_label(changeset)
        session[:new_label_attributes] = nil
        flash[:notice] = 'Created'
        response['Content-Type'] = 'application/json'
        { redirect: session[:last_grid_url] }.to_json
      end
    end
  end

  def label_designer_page(opts = {})
    Crossbeams::LabelDesigner::Config.configure do |config|
      config.label_config = label_config(opts).to_json
      config.label_sizes = LABEL_SIZES.to_json
    end

    page = Crossbeams::LabelDesigner::Page.new(opts[:id])
    # page.json_load_path = '/load_label_via_json' # Override config just before use.
    # page.json_save_path =  opts[:id].nil? ? '/save_label' : "/save_label/#{opts[:id]}"
    html = page.render
    css  = page.css
    js   = page.javascript

    # TODO: include csrf headers in the page....

    <<-HTML
    #{html}
    <% content_for :late_style do %>
      #{css}
    <% end %>
    <% content_for :late_javascript do %>
      #{js}
    <% end %>
    HTML
  end

  def label_instance_for_config(opts)
    if opts[:id]
      repo = LabelApp::LabelRepo.new
      label = repo.find_label(opts[:id])
      if opts[:cloned]
        label = LabelApp::Label.new(label.to_h.merge(id: nil, label_name: opts[:label_name]))
      end
      label
    else
      OpenStruct.new(opts)
    end
  end

  def label_config(opts)
    label = label_instance_for_config(opts)

    config = {
      labelState: opts[:id].nil? ? 'new' : 'edit',
      labelName:  label.label_name,
      savePath: label.id.nil? ? '/save_label' : "/save_label/#{label.id}",
      labelDimension: label.label_dimension,
      id: label.id,
      pixelPerMM: label.px_per_mm,
      labelJSON: label.label_json
    }
    config
  end

  PNG_REGEXP = %r{\Adata:([-\w]+/[-\w\+\.]+)?;base64,(.*)}m
  def image_from_param(param)
    data_uri_parts = param.match(PNG_REGEXP) || []
    # extension = MIME::Types[data_uri_parts[1]].first.preferred_extension
    # file_name = "testpng.#{extension}"
    Base64.decode64(data_uri_parts[2])
  end

  LABEL_SIZES = {
    '84x64': { 'width': '84', 'height': '64' },
    '84x100': { 'width': '84', 'height': '100' },
    '97x78': { 'width': '97', 'height': '78' },
    '78x97': { 'width': '78', 'height': '97' },
    '100x70': { 'width': '100', 'height': '70' },
    '100x84': { 'width': '100', 'height': '84' },
    '100x100': { 'width': '100', 'height': '100' },
    '105x250': { 'width': '105', 'height': '250' },
    '145x50': { 'width': '145', 'height': '50' }
  }.freeze
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
