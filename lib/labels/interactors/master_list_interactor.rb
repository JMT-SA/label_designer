# frozen_string_literal: true

module LabelApp
  class MasterListInteractor < BaseInteractor
    def repo
      @repo ||= MasterListRepo.new
    end

    def master_list(id)
      repo.find_master_list(id)
    end

    def validate_master_list_params(params)
      MasterListSchema.call(params)
    end

    def create_master_list(params)
      res = validate_master_list_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_master_list(res)
        log_transaction
      end
      instance = master_list(id)
      success_response("Created master list #{instance.list_type}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { list_type: ['This master list already exists'] }))
    end

    def update_master_list(id, params)
      res = validate_master_list_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_master_list(id, res)
        log_transaction
      end
      instance = master_list(id)
      success_response("Updated master list #{instance.list_type}",
                       instance)
    end

    def delete_master_list(id)
      name = master_list(id).list_type
      repo.transaction do
        repo.delete_master_list(id)
        log_transaction
      end
      success_response("Deleted master list #{name}")
    end
  end
end
