# frozen_string_literal: true

module LabelApp
  MasterListSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:list_type).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
  end
end
