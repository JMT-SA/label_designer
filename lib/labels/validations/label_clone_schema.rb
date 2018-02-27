# frozen_string_literal: true

module LabelApp
  LabelCloneSchema = Dry::Validation.Schema do
    optional(:id).filled(:int?)
    required(:label_name).filled(:str?)
  end
end
