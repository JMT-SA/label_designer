# frozen_string_literal: true

module LabelApp
  class PrinterRepo < RepoBase
    build_for_select :printers,
                     label: %i[printer_name printer_type],
                     value: :id,
                     no_active_check: true,
                     order_by: :printer_name

    crud_calls_for :printers, name: :printer, wrapper: Printer

    def delete_and_add_printers(printer_list)
      DB.transaction do
        DB[:printers].delete
        printer_list.each do |printer|
          rec = {
            printer_code: printer['Code'],
            printer_name: printer['Alias'],
            printer_type: printer['Type'],
            pixels_per_mm: printer['PixelMM'].to_i,
            printer_language: printer['Language']
          }
          create_printer(rec)
        end
      end
    end

    def distinct_px_mm
      DB[:printers].distinct.select_map(:pixels_per_mm).sort
    end

    def printers_for(px_per_mm)
      DB[:printers].where(pixels_per_mm: px_per_mm).map { |p| [p[:printer_name], p[:printer_code]] }
    end
  end
end
