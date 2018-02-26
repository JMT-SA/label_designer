# frozen_string_literal: true

module LabelApp
  class MasterList < Dry::Struct
    attribute :id, Types::Int
    attribute :list_type, Types::String
    attribute :description, Types::String
  end
end
