# frozen_string_literal: true

module LabelApp
  class LabelPublishNotification < Dry::Struct
    attribute :id, Types::Integer
    attribute :label_publish_log_id, Types::Integer
    attribute :label_id, Types::Integer
    attribute :url, Types::String
    attribute :complete, Types::Bool
    attribute :failed, Types::Bool
    attribute :errors, Types::String
  end
end
