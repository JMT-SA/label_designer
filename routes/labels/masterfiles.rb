# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class LabelDesigner < Roda
  # def authorised?(key, permission)
  #   true
  # end

  route 'masterfiles', 'labels' do |r|
    # MASTER LISTS
    # --------------------------------------------------------------------------
    r.on 'master_lists', Integer do |id|
      interactor = LabelApp::MasterListInteractor.new({}, {}, {}, {})

      # Check for notfound:
      r.on !interactor.exists?(:master_lists, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        if authorised?('masterfiles', 'edit')
          show_partial { Labels::Masterfiles::MasterList::Edit.call(id) }
        else
          dialog_permission_error
        end
      end
      r.is do
        r.get do       # SHOW
          if authorised?('masterfiles', 'read')
            show_partial { Labels::Masterfiles::MasterList::Show.call(id) }
          else
            dialog_permission_error
          end
        end
        r.patch do     # UPDATE
          response['Content-Type'] = 'application/json'
          res = interactor.update_master_list(id, params[:master_list])
          if res.success
            update_grid_row(id, changes: { list_type: res.instance[:list_type], description: res.instance[:description] },
                                notice: res.message)
          else
            content = show_partial { Labels::Masterfiles::MasterList::Edit.call(id, params[:master_list], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end
        r.delete do    # DELETE
          response['Content-Type'] = 'application/json'
          res = interactor.delete_master_list(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'master_lists' do
      interactor = LabelApp::MasterListInteractor.new({}, {}, {}, {})
      r.on 'new' do    # NEW
        if authorised?('masterfiles', 'new')
          show_partial_or_page(r) { Labels::Masterfiles::MasterList::New.call(form_values: { list_type: params[:key] }, remote: fetch?(r)) }
        else
          fetch?(r) ? dialog_permission_error : show_unauthorised
        end
      end
      r.post do        # CREATE
        res = interactor.create_master_list(params[:master_list])
        if res.success
          flash[:notice] = res.message
          if fetch?(r)
            redirect_via_json_to_last_grid
          else
            redirect_to_last_grid(r)
          end
        elsif fetch?(r)
          content = show_partial do
            Labels::Masterfiles::MasterList::New.call(form_values: params[:master_list],
                                                      form_errors: res.errors,
                                                      remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        else
          flash[:error] = res.message
          show_page do
            Labels::Masterfiles::MasterList::New.call(form_values: params[:master_list],
                                                      form_errors: res.errors,
                                                      remote: false)
          end
        end
      end
    end
  end
end
