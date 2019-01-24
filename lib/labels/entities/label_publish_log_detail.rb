# frozen_string_literal: true

module LabelApp
  class LabelPublishLogDetail < Dry::Struct
    attribute :id, Types::Integer
    attribute :label_publish_log_id, Types::Integer
    attribute :label_id, Types::Integer
    attribute :server_ip, Types::String
    attribute :destination, Types::String
    attribute :status, Types::String
    attribute :errors, Types::String
    attribute :complete, Types::Bool
    attribute :failed, Types::Bool
  end
end
