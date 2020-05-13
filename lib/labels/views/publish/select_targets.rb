# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class SelectTargets
        def self.call(opts, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:label_publish, :select_targets, printer_types: opts[:printer_types], targets: opts[:targets])
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/labels/publish/batch/select_labels'
              form.add_field :printer_type
              form.add_field :target_destinations
            end
          end

          layout
        end
      end
    end
  end
end
