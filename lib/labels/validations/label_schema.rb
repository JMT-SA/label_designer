# frozen_string_literal: true

module LabelApp
  LabelSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:label_name).filled(Types::StrippedString)
    optional(:label_dimension).filled(:string)
    optional(:px_per_mm).filled(:string)
    required(:container_type).filled(:string)
    required(:commodity).filled(:string)
    required(:market).filled(:string)
    required(:language).filled(:string)
    required(:print_rotation).filled(:integer)
    optional(:category).maybe(:string)
    optional(:sub_category).maybe(:string)
    optional(:multi_label).maybe(:bool)
    optional(:variable_set).filled(Types::StrippedString)
  end
end
