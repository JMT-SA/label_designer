# frozen_string_literal: true

module LabelApp
  LabelCloneSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:label_name).filled(Types::StrippedString)
  end
end
