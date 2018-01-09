# frozen_string_literal: true

module UiRules
  class PrinterRule < Base
    def generate_rules
      @this_repo = PrinterRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'printer'
    end

    def set_show_fields
      fields[:printer_code] = { renderer: :label }
      fields[:printer_name] = { renderer: :label }
      fields[:printer_type] = { renderer: :label }
      fields[:pixels_per_mm] = { renderer: :label }
      fields[:printer_language] = { renderer: :label }
    end

    def common_fields
      {
        printer_code: {},
        printer_name: {},
        printer_type: {},
        pixels_per_mm: {},
        printer_language: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_printer(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(printer_code: nil,
                                    printer_name: nil,
                                    printer_type: nil,
                                    pixels_per_mm: nil,
                                    printer_language: nil)
    end
  end
end