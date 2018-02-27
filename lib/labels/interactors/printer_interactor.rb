# frozen_string_literal: true

module LabelApp
  class PrinterInteractor < BaseInteractor
    def repo
      @repo ||= PrinterRepo.new
    end

    def refresh_printers
      mes_repo = MesServerRepo.new
      res = mes_repo.printer_list
      if res.success
        repo.delete_and_add_printers(res.instance)
        success_response('Refreshed printers')
      else
        failed_response(res.message)
      end
    end
  end
end
