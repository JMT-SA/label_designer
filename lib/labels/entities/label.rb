module LabelApp
  class Label < Dry::Struct
    attribute :id, Types::Integer
    attribute :label_name, Types::String
    attribute :label_json, Types::String
    attribute :label_dimension, Types::String.optional
    attribute :px_per_mm, Types::String.optional
    attribute :variable_xml, Types::String
    attribute :png_image, Types::Any # bytea,
    attribute :container_type, Types::String
    attribute :commodity, Types::String
    attribute :market, Types::String
    attribute :language, Types::String
    attribute :category, Types::String.optional
    attribute :sub_category, Types::String.optional
    attribute :multi_label, Types::Bool
    # attribute :sample_data, Types::JSON::Hash.optional
    attribute :sample_data, Types::Hash.optional
    attribute :variable_set, Types::String
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute :completed, Types::Bool
    attribute :approved, Types::Bool
    # attribute :extended_columns, Types::JSON::Hash.optional
    attribute :extended_columns, Types::Hash.optional

    #  label_name character varying(255) NOT NULL,
    #   label_json text,
    #   label_dimension character varying(255),
    #   variable_xml text,
    #   image_path character varying(255),
    #   created_at timestamp without time zone NOT NULL,
    #   updated_at timestamp without time zone NOT NULL,
    #   png_image bytea,
  end
end
