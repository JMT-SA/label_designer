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
        check_auth!('masterfiles', 'user_maintenance')
        show_partial { Development::Masterfiles::User::Edit.call(id) }
      end

      r.on 'act_as_user' do
        act_as_user(id)
        r.redirect '/'
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
          check_auth!('masterfiles', 'user_maintenance')
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
          res = interactor.update_user(id, params[:user])
          if res.success
            update_grid_row(id,
                            changes: { login_name: res.instance[:login_name],
                                       user_name: res.instance[:user_name],
                                       password_hash: res.instance[:password_hash],
                                       email: res.instance[:email] },
                            notice: res.message)
          else
            re_show_form(r, res) { Development::Masterfiles::User::Edit.call(id, params[:user], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('masterfiles', 'user_maintenance')
          res = interactor.delete_user(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'users' do
      interactor = DevelopmentApp::UserInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('masterfiles', 'user_maintenance')
        show_partial_or_page(r) { Development::Masterfiles::User::New.call(remote: fetch?(r)) }
      end

      r.on 'set_permissions', Integer do |id|
        r.get do
          check_auth!('masterfiles', 'user_permissions')
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

    # USER EMAIL GROUPS
    # --------------------------------------------------------------------------
    r.on 'user_email_groups', Integer do |id|
      interactor = DevelopmentApp::UserEmailGroupInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:user_email_groups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('masterfiles', 'edit')
        show_partial { Development::Masterfiles::UserEmailGroup::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('masterfiles', 'read')
          show_partial { Development::Masterfiles::UserEmailGroup::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_user_email_group(id, params[:user_email_group])
          if res.success
            update_grid_row(id, changes: { mail_group: res.instance[:mail_group] },
                                notice: res.message)
          else
            re_show_form(r, res) { Development::Masterfiles::UserEmailGroup::Edit.call(id, form_values: params[:user_email_group], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('masterfiles', 'delete')
          res = interactor.delete_user_email_group(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'user_email_groups' do
      interactor = DevelopmentApp::UserEmailGroupInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('masterfiles', 'new')
        show_partial_or_page(r) { Development::Masterfiles::UserEmailGroup::New.call(remote: fetch?(r)) }
      end
      r.on 'link_users', Integer do |id|
        r.post do
          res = interactor.link_users(id, multiselect_grid_choices(params))
          if fetch?(r)
            show_json_notice(res.message)
          else
            flash[:notice] = res.message
            r.redirect '/list/user_email_groups'
          end
        end
      end
      r.post do        # CREATE
        res = interactor.create_user_email_group(params[:user_email_group])
        if res.success
          row_keys = %i[
            id
            mail_group
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/development/masterfiles/user_email_groups/new') do
            Development::Masterfiles::UserEmailGroup::New.call(form_values: params[:user_email_group],
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
