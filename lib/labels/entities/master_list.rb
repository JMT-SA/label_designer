# frozen_string_literal: true

module LabelApp
  class MasterList < Dry::Struct
    attribute :id, Types::Integer
    attribute :list_type, Types::String
    attribute :description, Types::String
  end
end
