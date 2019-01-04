# frozen_string_literal: true

module LabelApp
  MasterListSchema = Dry::Validation.Params do
    optional(:id).filled(:int?)
    required(:list_type).filled(:str?)
    required(:description).filled(:str?)
  end
end
