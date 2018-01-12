# frozen_string_literal: true

LabelCloneSchema = Dry::Validation.Schema do
  optional(:id).filled(:int?)
  required(:label_name).filled(:str?)
end
