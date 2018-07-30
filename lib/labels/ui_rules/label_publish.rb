# frozen_string_literal: true

module UiRules
  class LabelPublishRule < Base
    def generate_rules
      @repo = LabelApp::PrinterRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields targets_fields if @mode == :select_targets

      form_name 'batch'
    end

    def targets_fields
      {
        printer_type: { renderer: :select, options: @options[:printer_types] },
        target_destinations: { renderer: :multi, options: @options[:targets], required: true }
      }
    end

    def make_form_object
      make_new_form_object
    end

    def make_new_form_object
      @form_object = OpenStruct.new(target_destinations: nil)
    end
  end
end
