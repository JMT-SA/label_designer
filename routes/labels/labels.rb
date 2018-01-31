# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class LabelDesigner < Roda
  def authorised?(key, permission)
    true
  end

  route 'labels', 'labels' do |r|
    # LABELS
    # --------------------------------------------------------------------------
    r.on 'labels', Integer do |id|
      interactor = LabelInteractor.new({}, {}, {}, {})

      # Check for notfound:
      r.on !interactor.exists?(:labels, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        if authorised?('labels', 'edit')
          view(inline: label_designer_page(id: id))
        else
          dialog_permission_error
        end
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
          content = show_partial do
            Labels::Labels::Label::Clone.call(id, form_values: params[:label],
                                                  form_errors: res.errors,
                                                  remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        end
      end

      r.on 'show_clone' do
        view(inline: label_designer_page(label_name: session[:new_label_attributes][:label_name],
                                         id: id,
                                         cloned: true))
      end

      r.on 'properties' do
        show_partial { Labels::Labels::Label::Properties.call(id) }
      end

      r.on 'background' do
        res = interactor.background_images(id)
        if res.success
          res.instance.map { |sub| "<img src='/labels/labels/labels/#{sub}/png' />" }.join("\n<hr>")
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

      r.on 'variable_list' do
        res = interactor.can_preview?(id)
        if res.success
          show_partial { Labels::Labels::Label::VariableList.call(id) }
        else
          dialog_warning(res.message)
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
        response['Content-Type'] = 'application/json'
        res = interactor.do_preview(id, screen_or_print, params[:label])
        if res.success
          filepath = Tempfile.open([res.instance.fname, '.png'], 'public/tempfiles') do |f|
            f.write(res.instance.body)
            f.path
          end
          { replaceDialog: { content: "<img src='/#{File.join('tempfiles', File.basename(filepath))}'>" } }.to_json
        else
          { flash: { error: res.message } }.to_json
        end
      end

      r.on 'link_sub_labels' do
        r.post do
          content = show_partial { Labels::Labels::Label::SortSubLabels.call(id, multiselect_grid_choices(params)) }
          update_dialog_content(content: content, notice: 'Re-order the sub-labels')
        end
      end

      r.on 'apply_sub_labels' do
        r.post do
          res = interactor.link_multi_label(id, params[:sublbl_sorted_ids])
          flash[:notice] = res.message # 'Linked sub-labels for a multi-label'
          redirect_via_json('/list/labels')
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
          if authorised?('labels', 'read')
            show_partial { Labels::Labels::Label::Show.call(id) }
          else
            dialog_permission_error
          end
        end
        r.patch do     # UPDATE
          response['Content-Type'] = 'application/json'
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
              sub_category:  grid_cols[:sub_category]
            },
                                notice: res.message)
          else
            content = show_partial { Labels::Labels::Label::Properties.call(id, params[:label], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end

        r.delete do    # DELETE
          response['Content-Type'] = 'application/json'
          res = interactor.delete_label(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'labels' do
      interactor = LabelInteractor.new({}, {}, {}, {})
      r.on 'new' do    # NEW
        if authorised?('labels', 'new')
          show_partial_or_page(fetch?(r)) { Labels::Labels::Label::New.call(remote: fetch?(r)) }
        else
          fetch?(r) ? dialog_permission_error : show_unauthorised
        end
      end
      r.post do        # CREATE
        res = nil
        p params
        res = if params[:label][:multi_label] == 't'
                interactor.create_label(params[:label])
              else
                interactor.pre_create_label(params[:label])
              end

        if res.success
          if params[:label][:multi_label] == 't'
            load_via_json("/list/sub_labels/multi?key=sub_labels&id=#{res.instance.id}&label_dimension=#{res.instance.label_dimension}")
          else
            session[:new_label_attributes] = res.instance
            qs = params[:label].map { |k, v| [CGI.escape(k.to_s), '=', CGI.escape(v.to_s)] }.map(&:join).join('&')
            if fetch?(r)
              redirect_via_json("/label_designer?#{qs}")
            else
              r.redirect "/label_designer?#{qs}"
            end
          end
        elsif fetch?(r)
          content = show_partial do
            Labels::Labels::Label::New.call(form_values: params[:label],
                                            form_errors: res.errors,
                                            remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        else
          flash[:error] = res.message
          show_page do
            Labels::Labels::Label::New.call(form_values: params[:label],
                                            form_errors: res.errors,
                                            remote: false)
          end
        end
      end
    end
  end
end
