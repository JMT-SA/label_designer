# frozen_string_literal: true

module DevelopmentApp
  class Status < Dry::Struct
    attribute :id, Types::Integer
    attribute :transaction_id, Types::Integer
    attribute :action_tstamp_tx, Types::DateTime
    attribute :table_name, Types::String
    attribute :row_data_id, Types::Integer
    attribute :status, Types::String
    attribute :comment, Types::String
    attribute :user_name, Types::String
  end
end
