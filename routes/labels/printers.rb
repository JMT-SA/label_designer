# frozen_string_literal: true

class LabelDesigner < Roda
  route 'printers', 'labels' do |r|
    # PRINTERS
    # --------------------------------------------------------------------------
    r.on 'printers', Integer do |id|
      interactor = PrinterInteractor.new({}, {}, {}, {})

      # Check for notfound:
      r.on !interactor.exists?(:printers, id) do
        handle_not_found(r)
      end

      r.get do       # SHOW
        show_partial { Labels::Printers::Printer::Show.call(id) }
      end
    end

    r.on 'printers' do
      interactor = PrinterInteractor.new({}, {}, {}, {})
      r.on 'refresh' do
        res = interactor.refresh_printers
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        if fetch?(r)
          redirect_via_json_to_last_grid
        else
          redirect_to_last_grid(r)
        end
      end
    end
  end
end
