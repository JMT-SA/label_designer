# frozen_string_literal: true

class Printer < Dry::Struct
  attribute :id, Types::Int
  attribute :printer_code, Types::String
  attribute :printer_name, Types::String
  attribute :printer_type, Types::String
  attribute :pixels_per_mm, Types::Int
  attribute :printer_language, Types::String
end
