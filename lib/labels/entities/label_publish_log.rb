# frozen_string_literal: true

module LabelApp
  class LabelPublishLog < Dry::Struct
    attribute :id, Types::Integer
    attribute :user_name, Types::String
    attribute :printer_type, Types::String
    attribute :publish_name, Types::String
    attribute :status, Types::String
    attribute :errors, Types::String
    attribute :complete, Types::Bool
    attribute :failed, Types::Bool
    attribute :created_at, Types::Time
    # attribute :publish_summary, Types::JSON::Hash.optional
    attribute :publish_summary, Types::Hash.optional
  end
end
