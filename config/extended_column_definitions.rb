# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for JSONB contents of various tables per client.
    #
    class ExtendedColumnDefinitions
      # TODO: how to apply the default?
      EXTENDED_COLUMNS = {
        labels: {
          'srcc' => {
            agent: { type: :string, required: true }, # masterlist_key, validation_format (pattern), display_format, lookup_rule, required, default
            pack_week: { type: :integer, required: true },
            srcc_order_nr: { type: :string },
            receiver_client: { type: :string },
            commodity: { type: :string, masterlist_key: 'commodity', required: true }, # lkp
            variety: { type: :string }, # lkp
            pack_code: { type: :string }, # lkp
            weight: { type: :string },
            brand: { type: :boolean },
            class: { type: :string, default: '1' },
            lot_number: { type: :string },
            comments: { type: :string }
          }
        }
      }.freeze

      # Takes the configuration rules for an extended column
      # and unpacks it into +form.add_field+ calls which are applied to the
      # form parameter.
      #
      # @param table [symbol] the name of the table that has an extended_columns field.
      # @param form [Crossbeams::Form] the form/fold in which to place the fields.
      def self.extended_columns_for_view(table, form)
        config = EXTENDED_COLUMNS.dig(table, AppConst::CLIENT_CODE)
        return if config.nil?
        config.keys.each { |k| form.add_field("extcol_#{k}".to_sym) }
      end
    end
  end
end
