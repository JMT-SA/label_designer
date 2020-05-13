# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class LabelDesigner < Roda
  route 'masterfiles', 'labels' do |r|
    # MASTER LISTS
    # --------------------------------------------------------------------------
    r.on 'master_lists', Integer do |id|
      interactor = LabelApp::MasterListInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:master_lists, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('master lists', 'edit')
        show_partial { Labels::Masterfiles::MasterList::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('master lists', 'read')
          show_partial { Labels::Masterfiles::MasterList::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_master_list(id, params[:master_list])
          if res.success
            update_grid_row(id, changes: { list_type: res.instance[:list_type], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Labels::Masterfiles::MasterList::Edit.call(id, params[:master_list], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('master lists', 'delete')
          res = interactor.delete_master_list(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end

    r.on 'master_lists' do
      interactor = LabelApp::MasterListInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('master lists', 'new')
        show_partial_or_page(r) { Labels::Masterfiles::MasterList::New.call(form_values: { list_type: params[:key] }, remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_master_list(params[:master_list])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/labels/masterfiles/master_lists/new') do
            Labels::Masterfiles::MasterList::New.call(form_values: params[:master_list],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
