# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

require 'roda'
require 'crossbeams/dataminer'
require 'crossbeams/layout'
require 'crossbeams/label_designer'
require 'yaml'
require 'base64'
require 'zip'
require 'dry-struct'
require 'dry-validation'
require 'net/http'
require 'uri'
# require './lib/db_connections'
require 'pry'

module Types
  include Dry::Types.module
end

module Crossbeams
  class FrameworkError < StandardError
  end
end

require './lib/crossbeams_responses'
require './lib/repo_base'
require './lib/base_interactor'
require './lib/base_service'
require './lib/ui_rules'
require './lib/library_versions'
Dir['./helpers/**/*.rb'].each { |f| require f }
Dir['./lib/applets/*.rb'].each { |f| require f }

ENV['ROOT'] = File.dirname(__FILE__)
LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')

Crossbeams::LabelDesigner::Config.configure do |config| # Set up configuration for label designer gem.
  # config.json_load_path = '/load_label'
  # config.json_save_path = '/save_label'
  # config.json_save_path = '/save_label'
end

class LabelDesigner < Roda
  include CommonHelpers

  use Rack::Session::Cookie, secret: 'some_nice_long_random_string_DSKJH4378EYR7EGKUFH', key: '_lbld_session'
  use Rack::MethodOverride # USe with all_verbs plugin to allow "r.delete" etc.

  plugin :all_verbs
  plugin :render
  plugin :assets, css: 'style.scss', precompiled: 'prestyle.css'
  plugin :public # serve assets from public folder.
  plugin :multi_route
  plugin :content_for, append: true
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
  plugin :json_parser
  plugin :data_grid, path: File.dirname(__FILE__),
                     list_url: '/list/%s/grid',
                     list_nested_url: '/list/%s/nested_grid',
                     list_multi_url: '/list/%s/grid_multi',
                     search_url: '/search/%s/grid',
                     filter_url: '/search/%s',
                     run_search_url: '/search/%s/run',
                     run_to_excel_url: '/search/%s/xls'

  Dir['./routes/*.rb'].each { |f| require f }

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    r.root do
      view('home')
      r.redirect('/list/labels')
    end

    r.multi_route

    r.is 'versions' do
      view(inline: LibraryVersions.new(:layout,
                                       :dataminer,
                                       :label_designer,
                                       :datagrid,
                                       :ag_grid,
                                       :selectr).to_html)
    end

    r.on 'label_designer' do
      r.is do
        view(inline: label_designer_page(label_name: params[:label_name],
                                         label_dimension: params[:label_dimension],
                                         px_per_mm: params[:px_per_mm]))
      end
    end

    r.on 'list' do
      r.on :id do |id|
        r.is do
          session[:last_grid_url] = "/list/#{id}"
          show_page { render_data_grid_page(id) }
        end

        r.on 'with_params' do
          if fetch?(r)
            show_partial { render_data_grid_page(id, query_string: request.query_string) }
          else
            session[:last_grid_url] = "/list/#{id}/with_params?#{request.query_string}"
            show_page { render_data_grid_page(id, query_string: request.query_string) }
          end
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          if params && !params.empty?
            render_data_grid_rows(id, nil, params)
          else
            render_data_grid_rows(id)
          end
        end
      end
    end

    # Generic code for grid searches.
    r.on 'search' do
      r.on :id do |id|
        r.is do
          render_search_filter(id, params)
        end

        r.on 'run' do
          session[:last_grid_url] = "/search/#{id}?rerun=y"
          show_page { render_search_grid_page(id, params) }
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          render_search_grid_rows(id, params)
        end

        r.on 'xls' do
          begin
            caption, xls = render_excel_rows(id, params)
            response.headers['content_type'] = 'application/vnd.ms-excel'
            response.headers['Content-Disposition'] = "attachment; filename=\"#{caption.strip.gsub(%r{[/:*?"\\<>\|\r\n]}i, '-') + '.xls'}\""
            response.write(xls) # NOTE: could this use streaming to start downloading quicker?
          rescue Sequel::DatabaseError => e
            view(inline: <<-HTML)
            <p style='color:red;'>There is a problem with the SQL definition of this report:</p>
            <p>Report: <em>#{caption}</em></p>The error message is:
            <pre>#{e.message}</pre>
            <button class="pure-button" onclick="crossbeamsUtils.toggleVisibility('sql_code', this);return false">
              <i class="fa fa-info"></i> Toggle SQL
            </button>
            <pre id="sql_code" style="display:none;"><%= sql_to_highlight(@rpt.runnable_sql) %></pre>
            HTML
          end
        end
      end
    end

    r.on 'save_label' do
      r.on :id do |id|
        r.post do
          repo = LabelRepo.new
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
        repo = LabelRepo.new
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
      config.label_sizes = label_sizes.to_json
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

  def label_config(opts)
    if opts[:id]
      repo  = LabelRepo.new
      label = repo.find_label(opts[:id])
    end
    config = { labelState: opts[:id].nil? ? 'new' : 'edit',
               labelName:  opts[:cloned] || label.nil? ? opts[:label_name] : label.label_name,
               savePath: opts[:cloned] || opts[:id].nil? ? '/save_label' : "/save_label/#{opts[:id]}",
               labelDimension: label.nil? ? opts[:label_dimension] : label.label_dimension,
               id: opts[:cloned] || opts[:id].nil? ? nil : opts[:id],
               pixelPerMM: label.nil? ? opts[:px_per_mm] : label.px_per_mm,
               labelJSON:  label.nil? ? {} : label.label_json }
    config
  end

  PNG_REGEXP = %r{\Adata:([-\w]+/[-\w\+\.]+)?;base64,(.*)}m
  def image_from_param(param)
    data_uri_parts = param.match(PNG_REGEXP) || []
    # extension = MIME::Types[data_uri_parts[1]].first.preferred_extension
    # file_name = "testpng.#{extension}"
    Base64.decode64(data_uri_parts[2])
  end

  def label_sizes
    sizes = {
      'A4': { 'width': '71', 'height': '54' },
      'A5': { 'width': '35', 'height': '21' },
      '8464': { 'width': '84', 'height': '64' },
      'Custom': { 'width': '84', 'height': '64' }
    }
    sizes
  end

  def make_label_zip(label, vars = nil)
    property_vars = vars ? vars.map { |k, v| "\n#{k}=#{v}" }.join : "\nF1=Variable Test Value"
    fname = label.label_name.strip.gsub(%r{[/:*?"\\<>\|\r\n]}i, '-')
    label_properties = %(Client: Name="NoSoft"\nF0=#{fname}#{property_vars}) # For testing only
    stringio = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry("#{fname}.png")
      zio.write label.png_image
      zio.put_next_entry("#{fname}.xml")
      zio.write label.variable_xml.chomp << "\n" # Ensure newline at end of file.
      zio.put_next_entry("#{fname}.properties")
      zio.write label_properties
    end
    [fname, stringio.string]
  end
end
