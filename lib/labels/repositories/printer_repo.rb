# frozen_string_literal: true

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
          printer_code: find_printer_code(printer), # Change to printer['Code'] once MesServer response changes.
          printer_name: printer['Alias'],
          printer_type: printer['Type'],
          pixels_per_mm: printer['PixelMM'].to_i,
          printer_language: printer['Language']
        }
        create_printer(rec)
      end
    end
  end

  def find_printer_code(printer)
    printer.keys.find { |key| key.start_with?('PRN') }
  end
end
