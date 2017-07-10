require 'roda'
require 'rom'
require 'rom-sql'
require 'rom-repository'
require 'crossbeams/dataminer'
require 'crossbeams/layout'
require 'crossbeams/label_designer'
require 'yaml'
require 'base64'
require 'dry-validation'
require './lib/db_connections'
Dir['./lib/labels/*.rb'].each { |f| require f }
require './repositories/user_repo'
require './repositories/label_repo'
Dir['./persistence/changesets/*.rb'].each { |f| require f }

Crossbeams::LabelDesigner::Config.configure do |config| # Set up configuration for label designer gem.
#   config.json_load_path = '/load_label'
  config.json_save_path = '/save_label'
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
        show_page { Label::New.call }
      end

      r.on 'create' do
        schema = Dry::Validation.Schema do
          required(:label_name).filled(:str?)
        end
        errors = schema.call(params[:label]).messages
        if errors.empty?
          qs = params[:label].map{|k,v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)]}.map(&:join).join("&")
          r.redirect "/label_designer?#{qs}"
        else
          flash.now[:error] = 'Unable to create label'
          show_page { Label::New.call(params[:label], errors) }
        end
      end

      r.on :id do |id|
        r.delete do
          repo = LabelRepo.new(DB.db)
          repo.delete(id)
          flash[:notice] = 'Deleted'
          redirect_to_last_grid(r)
        end

        r.post 'update' do
          schema = Dry::Validation.Schema do
            required(:label_name).filled(:str?)
          end
          errors = schema.call(params[:label]).messages
          if errors.empty?
            repo = LabelRepo.new(DB.db)
            changeset = repo.changeset(id, label_name: params[:label][:label_name],
                                           label_dimension: params[:label][:label_dimension]).map(:touch)
            repo.update(id, changeset)
            redirect_to_last_grid(r)
          else
            flash.now[:error] = 'Unable to update label'
            show_page { Label::Properties.call(id, params[:label], errors) }
          end
        end

        r.on 'edit' do
          view(inline: label_designer_page(id: id))
        end

        r.on 'clone' do
          show_page { Label::Clone.call(id) }
        end

        r.on 'properties' do
          # show_page { Label::Properties.call(id) }
          show_partial { Label::Properties.call(id) }
          # Show form for name + dimensions & then to label
        end

        r.on 'preview' do
          # repo = LabelRepo.new(DB.db)
          # label = repo.labels.by_pk(id).one
          # view(inline: "PREVIEW #{label.label_name}<p><img src='/label_designer/#{id}/png' /></p>")
          "<img src='/label_designer/#{id}/png' />"
        end

        r.on 'png' do
          response['Content-Type'] = 'image/png'
          repo = LabelRepo.new(DB.db)
          label = repo.labels.by_pk(id).one
          label.png_image
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
          repo = LabelRepo.new(DB.db)
          # changeset = repo.changeset(params[:functional_area]).map(:add_timestamps)
          # TODO: read params to get dim, id and name... and do update/create...
          file_name = "testeditpng.png"

          File.open(file_name, 'wb') do |file|
            file.write(image_from_param(params[:imageString]))
          end
          puts "ID is #{id}..."
          # NOTE: ROM changeset is compared to the existing data, so you need to supply ALL columns,
          # not just the changed ones (incl. created_at)
          changeset = repo.changeset(id, {label_json: params[:label],
                                       variable_xml: params[:XMLString],
                                       png_image: image_from_param(params[:imageString])}).map(:touch)
          # changeset = repo.changeset(UpdateChangeset).by_pk(id).data({label_json: params[:label],
          #                                                # label_name: 'a testa',
          #                                                # label_dimension: '8464',
          #                                                variable_xml: params[:XMLString],
          #                                                png_image: image_from_param(params[:imageString])})
          repo.update(id, changeset)
          # repo.update(changeset)
          flash[:notice] = 'Updated'
          # redirect_to_last_grid(r)
          # - save to db
          response['Content-Type'] = 'application/json'
          {redirect: "#{session[:last_grid_url]}"}.to_json
        end
      end

      r.post do
        repo = LabelRepo.new(DB.db)
        # changeset = repo.changeset(params[:functional_area]).map(:add_timestamps)
        # TODO: read params to get dim, id and name... and do update/create...
        file_name = "testpng.png"

        File.open(file_name, 'wb') do |file|
          file.write(image_from_param(params[:imageString]))
        end
        changeset = repo.changeset(NewChangeset).data({label_json: params[:label],
                                                       label_name: 'a testa',
                                                       label_dimension: '8464',
                                                       variable_xml: params[:XMLString],
                                                       png_image: image_from_param(params[:imageString])})
        repo.create(changeset)
        flash[:notice] = 'Created'
        # redirect_to_last_grid(r)
        # - save to db
        response['Content-Type'] = 'application/json'
        {redirect: "#{session[:last_grid_url]}"}.to_json
        # params.to_json
      end
    end
  end

  def label_designer_page(opts = {})
    Crossbeams::LabelDesigner::Config.configure do |config|
      config.label_config = label_config(opts).to_json
    end

    page = Crossbeams::LabelDesigner::Page.new(opts[:id])
    # page.json_load_path = '/load_label_via_json' # Override config just before use.
    page.json_save_path =  opts[:id].nil? ? '/save_label' : "/save_label/#{opts[:id]}"
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
      this_repo = LabelRepo.new(DB.db)
      label     = this_repo.labels.by_pk(opts[:id]).one
    end
    config = {labelState: opts[:id].nil? ? 'new' : 'edit',
              labelName:  label.nil? ? opts[:label_name] : label.label_name,
              labelJSON:  label.nil? ? {} : label.label_json,
              savePath: opts[:id].nil? ? '/save_label' : "/save_label/#{opts[:id]}",
              labelDimension: label.nil? ? opts[:label_dimension] : label.label_dimension,
              id: opts[:id].nil? ? nil : opts[:id] }
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
end
