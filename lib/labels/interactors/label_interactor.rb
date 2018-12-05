# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module LabelApp
  class LabelInteractor < BaseInteractor
    def repo
      @repo ||= LabelRepo.new
    end

    def label(id)
      repo.find_label(id)
    end

    def validate_label_params(params)
      LabelSchema.call(params)
    end

    def pre_create_label(params)
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      attrs = {
        container_type: params[:container_type],
        commodity: params[:commodity],
        market: params[:market],
        language: params[:language],
        category: params[:category],
        sub_category: params[:sub_category]
      }
      success_response('Ok', attrs)
    end

    def create_label(params)
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      id = nil
      repo.transaction do
        id = repo.create_label(res)
        log_transaction
      end
      instance = label(id)
      success_response("Created label #{instance.label_name}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { label_name: ['This label already exists'] }))
    end

    def update_label(id, params)
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      repo.transaction do
        repo.update_label(id, res)
        log_transaction
      end
      instance = label(id)
      success_response("Updated label #{instance.label_name}",
                       instance)
    end

    def delete_label(id)
      instance = label(id)
      repo.transaction do
        if instance.multi_label
          repo.delete_label_with_sub_labels(id)
        else
          repo.delete_label(id)
        end
        log_transaction
      end
      success_response("Deleted label #{instance.label_name}")
    end

    def link_multi_label(id, sub_label_ids)
      repo.link_multi_label(id, sub_label_ids)
      success_response('Linked sub-labels for a multi-label')
    end

    def validate_clone_label_params(params)
      LabelCloneSchema.call(params)
    end

    def can_preview?(id)
      if label(id).multi_label && repo.no_sub_labels(id).zero?
        failed_response('This multi-label does not have any linked sub-labels')
      else
        success_response('ok')
      end
    end

    def prepare_clone_label(id, params)
      res = validate_clone_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      instance = label(id)
      attrs = {
        label_name: params[:label_name],
        container_type: instance.container_type,
        commodity: instance.commodity,
        market: instance.market,
        language: instance.language,
        category: instance.category,
        sub_category: instance.sub_category
      }
      success_response('Ok', attrs)
    end

    def background_images(id)
      res = can_preview?(id)
      return res unless res.success
      ids = if label(id).multi_label
              repo.sub_label_ids(id)
            else
              [id]
            end
      success_response('ok', ids)
    end

    def png_image(id)
      instance = label(id)
      instance.png_image
    end

    def label_zip(id)
      instance = label(id)
      LabelFiles.new.make_label_zip(instance)
    end

    def label_export(id)
      instance = label(id)
      raise 'Multi-labels cannot be exported' if instance.multi_label
      LabelFiles.new.make_export_zip(instance)
    end

    def import_label(params) # rubocop:disable Metrics/AbcSize
      return failed_response('No file selected to import') unless params[:import_file] && (tempfile = params[:import_file][:tempfile])
      attrs = {
        label_name: params[:label_name],
        container_type: params[:container_type],
        commodity: params[:commodity],
        market: params[:market],
        language: params[:language],
        category: params[:category],
        sub_category: params[:sub_category]
      }
      attrs = LabelFiles.new.import_file(tempfile, attrs)
      id = nil
      repo.transaction do
        id = repo.create_label(attrs)
        log_transaction
      end
      instance = label(id)
      success_response("Imported label #{instance.label_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { label_name: ['This label already exists'] }))
    end

    def do_preview(id, screen_or_print, vars)
      instance = label(id)
      # Store the input variables:
      # repo.update_label(id, sample_data: "{#{vars.map { |k, v| %("#{k}":"#{v}") }.join(',')}}")
      repo.update_label(id, sample_data: repo.hash_to_jsonb_str(vars))

      fname, binary_data = LabelFiles.new.make_label_zip(instance, vars)
      # File.open('zz.zip', 'w') { |f| f.puts binary_data }

      mes_repo = MesServerRepo.new
      res = mes_repo.preview_label(screen_or_print, vars, fname, binary_data)
      if res.success
        success_response("Sent preview to #{screen_or_print}.", OpenStruct.new(fname: fname, body: res.instance))
      else
        failed_response(res.message)
      end
    end

    def refresh_multi_label_variables(id)
      repo.transaction do
        repo.refresh_multi_label_variables(id)
        log_transaction
      end
      success_response('Preview values have been built up from the sub-labels')
    end
  end
end
# rubocop:enable Metrics/ClassLength
