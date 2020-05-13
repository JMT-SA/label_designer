# frozen_string_literal: true

class LabelDesigner < Roda
  route 'mes_modules', 'labels' do |r|
    # MES MODULES
    # --------------------------------------------------------------------------
    r.on 'mes_modules', Integer do |id|
      interactor = LabelApp::MesModuleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:mes_modules, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('designs', 'read')
          show_partial { Labels::Designs::MesModule::Show.call(id) }
        end
      end
    end

    r.on 'mes_modules' do
      interactor = LabelApp::MesModuleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'refresh' do
        res = interactor.refresh_mes_modules
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end
    end
  end
end
