# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

class LabelDesigner < Roda
  route 'labels', 'labels' do |r|
    # LABELS
    # --------------------------------------------------------------------------
    r.on 'labels', Integer do |id|
      interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:labels, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('designs', 'edit')
        interactor.assert_permission!(:edit, id)
        @label_edit_page = true
        view(inline: interactor.label_designer_page(id: id))
      end

      r.on 'archive' do
        r.post do
          interactor.archive_label(id)
          flash[:notice] = 'Label has been archived'
          redirect_to_last_grid(r)
        end

        show_partial { Labels::Labels::Label::Archive.call(id, false) }
      end

      r.on 'un_archive' do
        r.post do
          interactor.un_archive_label(id)
          flash[:notice] = 'Label has been un-archived'
          redirect_to_last_grid(r)
        end

        show_partial { Labels::Labels::Label::Archive.call(id, true) }
      end

      r.on 'clone' do
        show_partial { Labels::Labels::Label::Clone.call(id) }
      end

      r.on 'clone_label' do
        res = interactor.prepare_clone_label(id, params[:label])
        if res.success
          session[:new_label_attributes] = res.instance
          redirect_via_json("/labels/labels/labels/#{id}/show_clone")
        else
          re_show_form(r, res) { Labels::Labels::Label::Clone.call(id, form_values: params[:label], form_errors: res.errors, remote: true) }
        end
      end

      r.on 'show_clone' do
        @label_edit_page = true
        view(inline: interactor.label_designer_page(label_name: session[:new_label_attributes][:label_name],
                                                    id: id,
                                                    cloned: true))
      end

      r.on 'properties' do
        interactor.assert_permission!(:edit, id)
        show_partial { Labels::Labels::Label::Properties.call(id) }
      end

      r.on 'background' do
        res = interactor.background_images(id)
        if res.success
          html = res.instance.map { |sub| "<img src='/labels/labels/labels/#{sub}/png' />" }.join("\n<hr>")
          update_dialog_content(content: html)
        else
          dialog_warning(res.message)
        end
      end

      r.on 'png' do
        response['Content-Type'] = 'image/png'
        interactor.png_image(id)
      end

      r.on 'download' do
        fname, binary_data = interactor.label_zip(id)
        response.headers['content_type'] = 'application/x-zip-compressed'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{fname}.zip\""
        response.write(binary_data)
      end

      r.on 'export' do
        check_auth!('designs', 'export')
        fname, binary_data = interactor.label_export(id)
        response.headers['content_type'] = 'application/x-zip-compressed'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{fname}.ldexport\""
        response.write(binary_data)
      end

      r.on 'variable_list' do
        res = interactor.can_preview?(id)
        if res.success
          show_partial { Labels::Labels::Label::VariableList.call(id) }
        else
          dialog_warning(res.message)
        end
      end

      r.on 'refresh_multi_label_variables' do
        res = interactor.refresh_multi_label_variables(id)
        if res.success
          update_dialog_content(content: "<br><div class='crossbeams-success-note'><p><strong>Updated:</strong></p><p>#{res.message}</p></div>")
        else
          dialog_error(res.message)
        end
      end

      r.on 'preview' do
        res = interactor.can_preview?(id)
        if res.success
          show_partial { Labels::Labels::Label::ScreenPreview.call(id) }
        else
          dialog_warning(res.message)
        end
      end

      r.on 'print_preview' do
        res = interactor.can_preview?(id)
        if res.success
          show_partial { Labels::Labels::Label::PrintPreview.call(id) }
        else
          dialog_warning(res.message)
        end
      end

      r.on 'send_preview', String do |screen_or_print|
        res = interactor.do_preview(id, screen_or_print, params[:label])
        if res.success
          filepath = Tempfile.open([res.instance.fname, '.png'], 'public/tempfiles') do |f|
            f.write(res.instance.body)
            f.path
          end
          File.chmod(0o644, filepath) # Ensure web app can read the image.
          update_dialog_content(content: "<img src='/#{File.join('tempfiles', File.basename(filepath))}'>")
        else
          { flash: { error: res.message } }.to_json
        end
      end

      r.on 'email_preview' do
        r.get do
          res = interactor.can_email_preview?(id)
          if res.success
            show_partial { Labels::Labels::Label::EmailPreview.call(id) }
          else
            dialog_warning(res.message)
          end
        end

        r.patch do
          res = interactor.email_preview(id, params[:label])
          if res.success
            show_json_notice(res.message)
          else
            re_show_form(r, res) { Labels::Labels::Label::EmailPreview.call(id, form_values: params[:label], form_errors: res.errors) }
          end
        end
      end

      r.on 'batch_print' do
        r.get do
          res = interactor.can_preview?(id)
          if res.success
            show_partial { Labels::Labels::Label::BatchPrint.call(id) }
          else
            dialog_warning(res.message)
          end
        end

        r.patch do
          res = interactor.batch_print(id, params[:label])
          if res.success
            show_json_notice(res.message)
          else
            re_show_form(r, res) { Labels::Labels::Label::BatchPrint.call(id, form_values: params[:label], form_errors: res.errors) }
          end
        end
      end

      r.on 'link_sub_labels' do
        r.post do
          content = render_partial { Labels::Labels::Label::SortSubLabels.call(id, multiselect_grid_choices(params)) }
          update_dialog_content(content: content, notice: 'Re-order the sub-labels')
        end
      end

      r.on 'apply_sub_labels' do
        r.post do
          res = interactor.link_multi_label(id, params[:sublbl_sorted_ids])
          flash[:notice] = res.message # 'Linked sub-labels for a multi-label'
          redirect_to_last_grid(r)
        end
      end

      r.on 'complete' do
        r.get do
          check_auth!('designs', 'edit')
          interactor.assert_permission!(:complete, id)
          show_partial { Labels::Labels::Label::Complete.call(id) }
        end

        r.post do
          res = interactor.complete_a_label(id, params[:label])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Labels::Labels::Label::Complete.call(id, params[:label], res.errors) }
          end
        end
      end

      r.on 'approve' do
        r.get do
          check_auth!('designs', 'approve')
          interactor.assert_permission!(:approve, id)
          show_partial { Labels::Labels::Label::Approve.call(id) }
        end

        r.post do
          res = interactor.approve_or_reject_a_label(id, params[:label])
          # If reject, send email to person who completed, but who was that... [completed_by, approved_by] (although this is in the status log)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Labels::Labels::Label::Approve.call(id, params[:label], res.errors) }
          end
        end
      end

      r.on 'reopen' do
        r.get do
          check_auth!('designs', 'edit')
          interactor.assert_permission!(:reopen, id)
          show_partial { Labels::Labels::Label::Reopen.call(id) }
        end

        r.post do
          res = interactor.reopen_a_label(id, params[:label])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Labels::Labels::Label::Reopen.call(id, params[:label], res.errors) }
          end
        end
      end

      # r.on 'send_preview' do
      #   r.on String do |screen_or_print|
      #     interactor.do_preview(id, screen_or_print)
      #   end
      #   # r.on String do |screen_or_print|
      #   # r.on 'screen' do
      #   #   do_preview(id, 'screen')
      #   # end
      #   # r.on 'print' do
      #   #   do_preview(id, 'print')
      #   # end
      #   # end
      # end

      r.is do
        r.get do       # SHOW
          check_auth!('designs', 'read')
          show_partial { Labels::Labels::Label::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_label(id, params[:label])
          if res.success
            grid_cols = res.instance.to_h
            update_grid_row(id, changes:
            {
              label_name: grid_cols[:label_name],
              container_type: grid_cols[:container_type],
              commodity: grid_cols[:commodity],
              market: grid_cols[:market],
              language: grid_cols[:language],
              category: grid_cols[:category],
              updated_by: grid_cols[:updated_by],
              sub_category:  grid_cols[:sub_category]
            }.merge(interactor.extended_columns_for_row(grid_cols)),
                                notice: res.message)
          else
            re_show_form(r, res) { Labels::Labels::Label::Properties.call(id, params[:label], res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('designs', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_label(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'labels' do
      interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('designs', 'new')
        interactor.assert_permission!(:create)
        set_last_grid_url('/list/labels/with_params?key=active', r)
        show_partial_or_page(r) { Labels::Labels::Label::New.call(remote: fetch?(r)) }
      end
      r.is do
        r.post do        # CREATE
          res = nil
          res = if params[:label][:multi_label] == 't'
                  interactor.create_label(params[:label])
                else
                  interactor.pre_create_label(params[:label])
                end

          if res.success
            if params[:label][:multi_label] == 't'
              load_via_json("/list/sub_labels/multi?key=sub_labels&id=#{res.instance.id}&label_dimension=#{res.instance.label_dimension}&variable_set=#{res.instance.variable_set}")
            else
              session[:new_label_attributes] = res.instance
              qs = params[:label].map { |k, v| [CGI.escape(k.to_s), '=', CGI.escape(v.to_s)] }.map(&:join).join('&')
              if fetch?(r)
                redirect_via_json("/label_designer?#{qs}")
              else
                r.redirect "/label_designer?#{qs}"
              end
            end
          else
            re_show_form(r, res, url: '/labels/labels/labels/new') do
              Labels::Labels::Label::New.call(form_values: params[:label],
                                              form_errors: res.errors,
                                              remote: fetch?(r))
            end
          end
        end
      end

      r.on 'import' do
        check_auth!('designs', 'export')
        set_last_grid_url('/list/labels/with_params?key=active', r)
        show_partial_or_page(r) { Labels::Labels::Label::Import.call(remote: fetch?(r)) }
      end

      r.on 'add_import' do
        res = interactor.import_label(params[:label])
        if res.success
          flash[:notice] = res.message
          r.redirect("/labels/labels/labels/#{res.instance.id}/edit")
        else
          flash[:error] = res.message
          r.redirect('/labels/labels/labels/import')
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
