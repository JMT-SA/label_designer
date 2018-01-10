# frozen_string_literal: true

LabelSchema = Dry::Validation.Schema do
  required(:label_name).filled(:str?)
  required(:container_type).filled(:str?)
  required(:commodity).filled(:str?)
  required(:market).filled(:str?)
  required(:language).filled(:str?)
  optional(:category).maybe(:str?)
  optional(:sub_category).maybe(:str?)
end
