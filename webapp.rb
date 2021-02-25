# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

require './app_loader'

Crossbeams::LabelDesigner::Config.configure do |config| # Set up configuration for label designer gem.
  # config.json_load_path = '/load_label'
  # config.json_save_path = '/save_label'
  # config.json_save_path = '/save_label'
end

class LabelDesigner < Roda
  include CommonHelpers
  include ErrorHelpers
  include MenuHelpers
  include DataminerHelpers
  include RmdHelpers

  use Rack::Session::Cookie, secret: 'some_nice_long_random_string_DSKJH4378EYR7EGKUFH', key: '_lbld_session', same_site: :lax
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
  plugin :render, template_opts: { default_encoding: 'UTF-8' }
  plugin :partials
  plugin :assets, css: 'style.scss', precompiled: 'prestyle.css', sri: nil # SRI: nil because integrity calculated incorrectly....
  plugin :public # serve assets from public folder.
  plugin :multi_route
  plugin :content_for, append: true
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true, # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
                csrf_header: 'X-CSRF-Token',
                skip_if: ->(req) do # rubocop:disable Style/Lambda
                  ENV['RACK_ENV'] == 'test' || AppConst::BYPASS_LOGIN_ROUTES.any? do |path|
                    if path.end_with?('*')
                      req.path.match?(/#{path}/)
                    else
                      req.path == path
                    end
                  end
                end
  plugin :json_parser
  plugin :message_bus
  plugin :status_handler
  plugin :cookies, path: '/', same_site: :lax
  plugin :rodauth, csrf: :rack_csrf do
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
    template_opts(layout_opts: { path: File.join(ENV['ROOT'], 'views/layout_auth.erb') })
    login_return_to_requested_location? true
  end
  if ENV['RACK_ENV'] == 'development'
    plugin :enhanced_logger, filter: ->(path) { path.start_with?('/terminus') } # || path.start_with?('/js/') || path.start_with?('/css/') } # , trace_missed: true
  end
  unless ENV['RACK_ENV'] == 'development' && ENV['NO_ERR_HANDLE']
    plugin :error_mail, to: AppConst::ERROR_MAIL_RECIPIENTS,
                        from: AppConst::SYSTEM_MAIL_SENDER,
                        prefix: "[Error #{AppConst::ERROR_MAIL_PREFIX}] "
    plugin :error_handler do |e|
      error_mail(e) unless [Crossbeams::AuthorizationError,
                            Crossbeams::TaskNotPermittedError,
                            Crossbeams::InfoError,
                            Sequel::UniqueConstraintViolation,
                            Sequel::ForeignKeyConstraintViolation].any? { |o| e.is_a? o }
      show_error(e, request.has_header?('HTTP_X_CUSTOM_REQUEST_TYPE'))
      # = if prod and unexpected exception type, just display "something whent wrong" and log
    end
  end
  Dir['./routes/*.rb'].sort.each { |f| require f }

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    initialize_route_instance_vars

    ### p request.ip
    # Routes that must work without authentication
    # --------------------------------------------
    r.on 'webquery', String do |id|
      # A dummy user
      user = DevelopmentApp::User.new(id: 0, login_name: 'webquery', user_name: 'webquery', password_hash: 'dummy', email: nil, active: true)
      interactor = DataminerApp::PreparedReportInteractor.new(user, {}, { route_url: request.path, request_ip: request.ip }, {})
      interactor.prepared_report_as_html(id)
    end

    # https://support.office.com/en-us/article/import-data-from-database-using-native-database-query-power-query-f4f448ac-70d5-445b-a6ba-302db47a1b00?ui=en-US&rs=en-US&ad=US
    r.on 'xmlreport', String do |id|
      # A dummy user
      user = DevelopmentApp::User.new(id: 0, login_name: 'webquery', user_name: 'webquery', password_hash: 'dummy', email: nil, active: true)
      interactor = DataminerApp::PreparedReportInteractor.new(user, {}, { route_url: request.path, request_ip: request.ip }, {})
      interactor.prepared_report_as_xml(id)
    end
    # Do the same as XML?
    # --------------------------------------------

    r.on 'loading_window' do
      view(inline: 'Loading...', layout: 'layout_loading')
    end

    # OVERRIDE RodAuth's Login form:
    # r.get 'login' do
    #   if @registered_mobile_device
    #     @no_logout = true
    #     view(:login, layout: 'layout_rmd')
    #   else
    #     view(:login)
    #   end
    # end

    unless AppConst::BYPASS_LOGIN_ROUTES.any? do |path|
      if path.end_with?('*')
        request.path.match?(/#{path}/)
      else
        request.path == path
      end
    end
      r.rodauth
      # Store this path before login so we can redirect after login. NB. Only a GET request!
      # response.set_cookie('pre_login_path', r.fullpath) unless rodauth.logged_in? || r.path == '/login' || !request.get? || fetch?(r)
      rodauth.require_authentication
      r.redirect('/login') if current_user.nil? # Session might have the incorrect user_id
    end

    r.root do
      # TODO: Config this, and maybe set it up per user.
      if @registered_mobile_device && !@hybrid_device
        r.redirect @rmd_start_page || '/rmd/home'
      else
        # page = user_homepage
        # r.redirect page unless page.nil?
        r.redirect('/list/labels/with_params?key=active')
      end
    end

    return_json_response if fetch?(r)
    r.multi_route

    r.on 'iframe', Integer do |id|
      repo = SecurityApp::MenuRepo.new
      pf = repo.find_program_function(id)
      view(inline: %(<iframe src="#{pf.url}" title="#{pf.program_function_name}" width="100%" style="height:80vh"></iframe>))
    end

    r.is 'logout' do
      if session[:act_as_user_id]
        revert_to_logged_in_user
        r.redirect('/')
      else
        rodauth.logout
        flash[:notice] = 'Logged out'
        r.redirect('/login')
      end
    end

    r.is 'versions' do
      versions = LibraryVersions.new(:layout,
                                     :dataminer,
                                     :label_designer,
                                     :datagrid,
                                     :ag_grid,
                                     :choices,
                                     :sortable,
                                     :konva,
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

    r.is 'client_settings' do
      require './config/env_var_rules'

      en = EnvVarRules.new
      settings = en.client_settings
      @layout = Crossbeams::Layout::Page.build do |page, _|
        page.section do |section|
          section.add_text("Client Settings &mdash; for <span class='orange'>#{AppConst::CLIENT_CODE}</span>", wrapper: :h2)
          AppConst.constants.grep(/CR_/).sort.each do |const|
            kl = AppConst.const_get(const)
            next unless kl.class.name.start_with?('Crossbeams::')

            section.add_text("#{kl.rule_name} (AppConst::#{const})", wrapper: :h3)
            kl.check_client_setting_keys.each do |msg|
              section.add_notice msg, notice_type: :warning
            end
            # section.add_text key_problem unless key_problem.nil?
            section.add_table(kl.to_table, %i[method value description], cell_classes: { method: ->(_) { 'pad' },
                                                                                         value: ->(_) { 'pad' },
                                                                                         description: ->(_) { 'pad' } })
          end
          section.add_text('Constants', wrapper: :h3)
          section.add_text('Note: some values have spaces inserted after commas to make the display wrap better. Be aware of this if copying a setting from here.', wrapper: :em)
          section.add_table(settings, %i[key env_val const_val], header_captions: { env_val: 'Environment variable value', const_val: 'Value in AppConst' })
        end
      end
      view('crossbeams_layout_page')
    end

    r.is 'not_found' do
      response.status = 404
      view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
    end

    r.on 'terminus' do
      r.message_bus
      # view(inline: 'Maybe we show all unattended messages for a user here')
    end

    # LABEL DESIGNER
    # ----------------------------------------------------------------------

    r.on 'label_designer' do
      interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.is do
        @label_edit_page = true
        view(inline: interactor.label_designer_page(label_name: params[:label_name],
                                                    label_dimension: params[:label_dimension],
                                                    variable_set: params[:variable_set],
                                                    px_per_mm: params[:px_per_mm]))
      end
    end

    r.on 'save_label' do
      interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on :id do |id|
        r.post do
          repo = LabelApp::LabelRepo.new
          img = if AppConst::NEW_FEATURE_LBL_PREPROCESS
                  Sequel.blob(interactor.image_from_param_without_alpha(params[:imageString]))
                else
                  Sequel.blob(interactor.image_from_param(params[:imageString]))
                end

          changeset = { label_json: params[:label],
                        variable_xml: params[:XMLString],
                        png_image: img }

          DB.transaction do
            repo.update_label(id, interactor.include_updated_by_in_changeset(changeset))
            repo.log_action(user_name: current_user.user_name, context: 'update label', route_url: request.path, request_ip: request.ip)
          end

          flash[:notice] = 'Updated'
          redirect_via_json "/labels/labels/labels/#{id}/edit"
        end
      end

      r.post do
        # if session new_label_attr nil? redirect to list with an error message
        repo = LabelApp::LabelRepo.new
        extra_attributes = session[:new_label_attributes] ### WHAT IF THESE nil? (as happened at SRCC at 00:40) <session cleared? problem if cloned? OR double-send? - 1st end has session data and second has it replaced with nil...>
        extcols = interactor.select_extended_columns_params(extra_attributes)
        from_id = extra_attributes[:cloned_from_id]
        img = if AppConst::NEW_FEATURE_LBL_PREPROCESS
                Sequel.blob(interactor.image_from_param_without_alpha(params[:imageString]))
              else
                Sequel.blob(interactor.image_from_param(params[:imageString]))
              end
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
                      variable_set: extra_attributes[:variable_set],
                      variable_xml: params[:XMLString],
                      png_image: img }

        id = nil
        DB.transaction do
          id = repo.create_label(interactor.include_created_by_in_changeset(interactor.add_extended_columns_to_changeset(changeset, repo, extcols)))
          if from_id.nil?
            repo.log_status(:labels, id, 'CREATED', user_name: current_user.user_name)
          else
            from_lbl = repo.find_label(from_id)
            repo.log_status(:labels, id, 'CLONED', comment: "from #{from_lbl.label_name}", user_name: current_user.user_name)
          end
          repo.log_action(user_name: current_user.user_name, context: 'create label', route_url: request.path, request_ip: request.ip)
        end
        session[:new_label_attributes] = nil
        flash[:notice] = 'Created'
        redirect_via_json "/labels/labels/labels/#{id}/edit"
      end
    end
  end

  status_handler(404) do
    view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
  end

  def render_asciidoc(content, image_dir = '/documentation_images')
    <<~HTML
      <div id="asciidoc-content">
        #{Asciidoctor.convert(content, safe: :safe, attributes: { 'source-highlighter' => 'coderay', 'coderay-css' => 'style', 'imagesdir' => image_dir })}
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
