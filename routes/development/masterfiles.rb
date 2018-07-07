# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

class LabelDesigner < Roda
  route 'masterfiles', 'development' do |r|
    # USERS
    # --------------------------------------------------------------------------
    r.on 'users', Integer do |id|
      interactor = DevelopmentApp::UserInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:users, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('masterfiles', 'edit')
        show_partial { Development::Masterfiles::User::Edit.call(id) }
      end
      r.on 'details' do
        r.get do
          show_partial { Development::Masterfiles::User::Details.call(id) }
        end
        r.patch do
          # User updates own password
          res = interactor.change_user_password(id, params[:user])
          if res.success
            show_json_notice res.message
          else
            re_show_form(r, res, url: "/development/masterfiles/users/#{id}/details") do
              Development::Masterfiles::User::Details.call(id,
                                                           form_values: {}, # Do not re-show password values...
                                                           form_errors: res.errors)
            end
          end
        end
      end
      r.on 'change_password' do
        r.get do
          check_auth!('masterfiles', 'edit')
          show_partial { Development::Masterfiles::User::ChangePassword.call(id) }
        end
        r.patch do
          res = interactor.set_user_password(id, params[:user])
          if res.success
            show_json_notice res.message
          else
            re_show_form(r, res, url: "/development/masterfiles/users/#{id}/change_password") do
              Development::Masterfiles::User::ChangePassword.call(id,
                                                                  form_values: {}, # Do not re-show password values...
                                                                  form_errors: res.errors)
            end
          end
        end
      end
      r.is do
        r.get do       # SHOW
          check_auth!('masterfiles', 'read')
          show_partial { Development::Masterfiles::User::Show.call(id) }
        end
        r.patch do     # UPDATE
          return_json_response
          res = interactor.update_user(id, params[:user])
          if res.success
            update_grid_row(id,
                            changes: { login_name: res.instance[:login_name],
                                       user_name: res.instance[:user_name],
                                       password_hash: res.instance[:password_hash],
                                       email: res.instance[:email],
                                       active: res.instance[:active] },
                            notice: res.message)
          else
            content = show_partial { Development::Masterfiles::User::Edit.call(id, params[:user], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end
        r.delete do    # DELETE
          return_json_response
          check_auth!('masterfiles', 'delete')
          res = interactor.delete_user(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'users' do
      interactor = DevelopmentApp::UserInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('masterfiles', 'new')
        show_partial_or_page(r) { Development::Masterfiles::User::New.call(remote: fetch?(r)) }
      end

      r.on 'set_permissions', Integer do |id|
        r.get do
          check_auth!('masterfiles', 'edit')
          ids = multiselect_grid_choices(params)
          show_partial { Development::Masterfiles::User::ApplySecurityGroupToProgram.call(id, ids) }
        end
        r.patch do
          ids = multiselect_grid_choices(params[:permission])
          res = interactor.set_user_permissions(id, ids, params[:permission])
          if res.success
            update_grid_row(ids,
                            changes: { security_group_name: res.instance[:security_group_name],
                                       permissions: res.instance[:permissions] },
                            notice: res.message)
          else
            re_show_form(r, res, url: "/development/masterfiles/users/set_permissions/#{id}") do
              Development::Masterfiles::User::ApplySecurityGroupToProgram.call(id,
                                                                               ids,
                                                                               form_values: params[:permission],
                                                                               form_errors: res.errors)
            end
          end
        end
      end
      r.post do        # CREATE
        res = interactor.create_user(params[:user])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/development/masterfiles/users/new') do
            Development::Masterfiles::User::New.call(form_values: params[:user],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
