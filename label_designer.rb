require 'roda'
require 'crossbeams/dataminer'
require 'crossbeams/layout'
require 'crossbeams/label_designer'
require 'yaml'
require 'base64'
require 'zip'
require 'dry-validation'
require 'dry-struct'
require 'sequel'
require 'net/http'
require 'uri'
require './lib/db_connections'
require './lib/repo_base'

module Types
  include Dry::Types.module
end

module Crossbeams
  class FrameworkError < StandardError
  end
end

Dir['./lib/applets/*.rb'].each { |f| require f }

#=================================================
#### TEMPORARY QUICK CONFIG FOR JF SERVER URI ####
#=================================================
LABEL_SERVER_URI = 'http://localhost:9292/uploads'
#=================================================

Crossbeams::LabelDesigner::Config.configure do |config| # Set up configuration for label designer gem.
  # config.json_load_path = '/load_label'
  # config.json_save_path = '/save_label'
  # config.json_save_path = '/save_label'
end
DB = DBConnections.new

class LabelDesigner < Roda
  use Rack::Session::Cookie, secret: "some_nice_long_random_string_DSKJH4378EYR7EGKUFH", key: "_lbld_session"
  use Rack::MethodOverride # USe with all_verbs plugin to allow "r.delete" etc.

  plugin :all_verbs
  plugin :render
  plugin :assets, css: 'style.scss'
  plugin :public # serve assets from public folder.
  plugin :content_for, append: true
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
  plugin :json_parser
  plugin :data_grid, path: File.dirname(__FILE__),
                     list_url: '/list/%s/grid',
                     search_url: '/search/%s/grid',
                     filter_url: '/search/%s',
                     run_search_url: '/search/%s/run',
                     run_to_excel_url: '/search/%s/xls'

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'

    r.public

    r.root do
      view('home')
      r.redirect('/list/labels')
    end

    r.is 'versions' do
      s = '<h2>Gem Versions</h2><ul><li>'
      s << [Crossbeams::Dataminer,
            Crossbeams::Layout,
            Crossbeams::LabelDesigner,
            Roda::DataGrid].map { |k| "#{k}: #{k.const_get('VERSION')}" }.join('</li><li>')
      s << '</li></ul>'
      view(inline: s)
    end

    r.on 'label_designer' do
      r.is do
        view(inline: label_designer_page(label_name: params[:label_name],
                                         label_dimension: params[:label_dimension]))
      end

      r.on 'new' do
        show_page { LabelView::New.call }
      end

      r.on 'create' do
        # schema = Dry::Validation.Schema do
        #   required(:label_name).filled(:str?)
        # end
        # errors = schema.call(params[:label]).messages
        errors = LabelSchema.(params[:label]).messages
        if errors.empty?
          qs = params[:label].map{|k,v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)]}.map(&:join).join("&")
          r.redirect "/label_designer?#{qs}"
        else
          flash.now[:error] = 'Unable to create label'
          show_page { LabelView::New.call(params[:label], errors) }
        end
      end

      r.on :id do |id|
        r.delete do
          repo = LabelRepo.new
          repo.delete(id)
          flash[:notice] = 'Deleted'
          redirect_to_last_grid(r)
        end

        r.post 'update' do
          res = LabelSchema.(params[:label])
          errors = res.messages
          if errors.empty?
            repo = LabelRepo.new
            repo.update(id, res.to_h)
            # redirect_to_last_grid(r)
            response['Content-Type'] = 'application/json'
            {updateGridInPlace: { id: id.to_i, changes: { label_name: res[:label_name] } },
             flash: { notice: "Updated #{res[:label_name]}" } }.to_json
          else
            content = show_partial { LabelView::Properties.call(id, params[:label], errors) }
            {replaceDialog: { content: content }, flash: { error: 'Validation error' } }.to_json
          end
        end

        r.on 'edit' do
          view(inline: label_designer_page(id: id))
        end

        r.on 'clone' do
          show_page { LabelView::Clone.call(id) }
        end

        r.on 'clone_label' do
          view(inline: label_designer_page(label_name: params[:label][:label_name],
                                           id: params[:label][:id],
                                           cloned: true))
        end

        r.on 'properties' do
          # show_page { LabelView::Properties.call(id) }
          show_partial { LabelView::Properties.call(id) }
          # Show form for name + dimensions & then to label
        end

        r.on 'preview' do
          "<img src='/label_designer/#{id}/png' />"
        end

        r.on 'png' do
          response['Content-Type'] = 'image/png'
          repo = LabelRepo.new
          label = repo.find(id)
          label.png_image
        end

        r.on 'download' do
          repo  = LabelRepo.new
          label = repo.find(id)
          fname, binary_data = make_label_zip(label)
          response.headers['content_type'] = 'application/x-zip-compressed'
          response.headers['Content-Disposition'] = "attachment; filename=\"#{fname}.zip\""
          response.write(binary_data)
        end

        r.on 'upload' do
          <<-EOS
          <div id="crossbeams-processing" class="content-target content-loading"></div>
          <script>
            var content_div = document.querySelector('#crossbeams-processing');

            fetch('/label_designer/#{id}/upload_file')
            .then(function(response) {
              return response.text();
            })
            .then(function(responseText) {
              content_div.classList.remove('content-loading');
              content_div.innerHTML = responseText;
            });
          </script>
          EOS
        end

        r.on 'upload_file' do
          begin
            close_button       = '<p><button class="close-dialog">Close</button></p>'
            repo               = LabelRepo.new
            label              = repo.find(id)
            fname, binary_data = make_label_zip(label)
            uri                = URI.parse(LABEL_SERVER_URI)
            BOUNDARY           = "AaB03x"

            post_body = []
            post_body << "--#{BOUNDARY}\r\n"
            post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"#{fname}.zip\"\r\n"
            post_body << "Content-Type: application/x-zip-compressed\r\n"
            post_body << "\r\n"
            post_body << binary_data #File.read(file)
            post_body << "\r\n--#{BOUNDARY}--\r\n"

            http = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Post.new(uri.request_uri)
            request.body = post_body.join
            request["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"

            response = http.request(request)
            if response.code == '200'
              "<strong>The upload was successful</strong><p>#{response.body}</p>#{close_button}"
            elsif response.code.start_with?('5')
              "The destination server encountered an error. The response code is #{response.code}#{close_button}"
            else
              "The request was not successful. The response code is #{response.code}#{close_button}"
            end
          rescue Timeout::Error => e
            "The call to the server timed out.#{close_button}"
          rescue Errno::ECONNREFUSED => e
            "The connection was refused. <p>Perhaps the server is not running.</p>#{close_button}"
          rescue StandardError => e
            "There was an error: <span style='display:none'>#{e.class.name}</span><p>#{e.message}</p>#{close_button}"
          end
        end
      end
    end

    r.on 'list' do
      r.on :id do |id|
        r.is do
          session[:last_grid_url] = "/list/#{id}"
          show_page { render_data_grid_page(id) }
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          render_data_grid_rows(id)
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
            response.headers['content_type'] = "application/vnd.ms-excel"
            response.headers['Content-Disposition'] = "attachment; filename=\"#{caption.strip.gsub(/[\/:*?"\\<>\|\r\n]/i, '-') + '.xls'}\""
            response.write(xls) # NOTE: could this use streaming to start downloading quicker?

          rescue Sequel::DatabaseError => e
            view(inline: <<-EOS)
            <p style='color:red;'>There is a problem with the SQL definition of this report:</p>
            <p>Report: <em>#{caption}</em></p>The error message is:
            <pre>#{e.message}</pre>
            <button class="pure-button" onclick="crossbeamsUtils.toggleVisibility('sql_code', this);return false">
              <i class="fa fa-info"></i> Toggle SQL
            </button>
            <pre id="sql_code" style="display:none;"><%= sql_to_highlight(@rpt.runnable_sql) %></pre>
            EOS
          end
        end
      end
    end

    r.on 'save_label' do
      r.on :id do |id|
        r.post do
          repo = LabelRepo.new
          # TODO: read params to get dim, id and name... and do update/create...
          # file_name = "testeditpng.png"
          #
          # File.open(file_name, 'wb') do |file|
          #   file.write(image_from_param(params[:imageString]))
          # end
          changeset = {label_json: params[:label],
                       variable_xml: params[:XMLString],
                       png_image: Sequel.blob(image_from_param(params[:imageString]))}
          # puts ">>> IMG: #{image_from_param(params[:imageString])}"
          repo.update(id, changeset)

          flash[:notice] = 'Updated'
          response['Content-Type'] = 'application/json'
          {redirect: "#{session[:last_grid_url]}"}.to_json
        end
      end

      r.post do
        repo = LabelRepo.new
        # changeset = repo.changeset(params[:functional_area]).map(:add_timestamps)
        # TODO: read params to get dim, id and name... and do update/create...
        file_name = "testpng.png"

        File.open(file_name, 'wb') do |file|
          file.write(image_from_param(params[:imageString]))
        end
        changeset = {label_json: params[:label],
                     label_name: params[:labelName],
                     label_dimension: '8464',
                     variable_xml: params[:XMLString],
                     png_image: Sequel.blob(image_from_param(params[:imageString]))}
        repo.create(changeset)
        flash[:notice] = 'Created'
        response['Content-Type'] = 'application/json'
        {redirect: "#{session[:last_grid_url]}"}.to_json
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

    <<-EOC
    #{html}
    <% content_for :late_style do %>
      #{css}
    <% end %>
    <% content_for :late_javascript do %>
      #{js}
    <% end %>
    EOC
  end

  def label_config(opts)
    if opts[:id]
      repo  = LabelRepo.new
      label = repo.find(opts[:id])
    end
    config = {labelState: opts[:id].nil? ? 'new' : 'edit',
              labelName:  opts[:cloned] || label.nil? ? opts[:label_name] : label.label_name,
              labelJSON:  label.nil? ? {} : label.label_json,
              savePath: opts[:cloned] || opts[:id].nil? ? '/save_label' : "/save_label/#{opts[:id]}",
              labelDimension: label.nil? ? opts[:label_dimension] : label.label_dimension,
              id: opts[:cloned] || opts[:id].nil? ? nil : opts[:id] }
    config
  end

  def redirect_to_last_grid(r)
    r.redirect session[:last_grid_url]
  end

  def show_page(&block)
    @layout = block.yield
    @layout.add_csrf_tag(csrf_tag)
    view('crossbeams_layout_page')
  end

  def show_partial(&block)
    @layout = block.yield
    @layout.add_csrf_tag(csrf_tag)
    @layout.render
  end

  PNG_REGEXP = /\Adata:([-\w]+\/[-\w\+\.]+)?;base64,(.*)/m
  def image_from_param(param)
    data_uri_parts = param.match(PNG_REGEXP) || []
    # extension = MIME::Types[data_uri_parts[1]].first.preferred_extension
    # file_name = "testpng.#{extension}"
    Base64.decode64(data_uri_parts[2])
  end

  def label_sizes
    sizes = {
      'a4': {'width': '71', 'height': '54'},
      'a5': {'width': '35', 'height': '21'},
      '8464': {'width': '84', 'height': '64'},
      'custom': {'width': '84', 'height': '64'}
    }
    sizes
  end

  def make_label_zip(label)
    fname = label.label_name.strip.gsub(/[\/:*?"\\<>\|\r\n]/i, '-')
    label_properties = %Q{Client: Name="NoSoft"}
    stringio = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry("#{fname}.png")
      zio.write label.png_image
      zio.put_next_entry("#{fname}.xml")
      zio.write label.variable_xml
      zio.put_next_entry("#{fname}.properties")
      zio.write label_properties
    end
    return [fname, stringio.string]
  end
end
