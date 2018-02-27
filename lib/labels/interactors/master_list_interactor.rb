# frozen_string_literal: true

module LabelApp
  class MasterListInteractor < BaseInteractor
    def repo
      @repo ||= MasterListRepo.new
    end

    def master_list(cached = true)
      if cached
        @master_list ||= repo.find_master_list(@id)
      else
        @master_list = repo.find_master_list(@id)
      end
    end

    def validate_master_list_params(params)
      MasterListSchema.call(params)
    end

    def create_master_list(params)
      res = validate_master_list_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      @id = repo.create_master_list(res)
      success_response("Created master list #{master_list.list_type}",
                       master_list)
    end

    def update_master_list(id, params)
      @id = id
      res = validate_master_list_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      repo.update_master_list(id, res)
      success_response("Updated master list #{master_list.list_type}",
                       master_list(false))
    end

    def delete_master_list(id)
      @id = id
      name = master_list.list_type
      repo.delete_master_list(id)
      success_response("Deleted master list #{name}")
    end
  end
end
