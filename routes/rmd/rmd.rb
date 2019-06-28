# frozen_string_literal: true

class LabelDesigner < Roda # rubocop:disable Metrics/ClassLength
  # DELIVERIES
  # --------------------------------------------------------------------------
  route 'deliveries', 'rmd' do |r| # rubocop:disable Metrics/BlockLength
    # PUTAWAYS
    # --------------------------------------------------------------------------
    r.on 'putaways' do # rubocop:disable Metrics/BlockLength
      # Interactor
      r.on 'new' do    # NEW
        # check auth...
        details = retrieve_from_local_store(:delivery_putaway) || {}
        form = Crossbeams::RMDForm.new(details,
                                       form_name: :putaway,
                                       progress: details[:delivery_id] ? details[:progress] : nil, # 'Delivery 123: 3 of 5 items complete' : nil,
                                       notes: 'Please scan the Delivery number and the SKU number, then scan the Location and enter the quantity to be putaway.',
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Delivery putaway',
                                       action: '/rmd/deliveries/putaways',
                                       button_caption: 'Putaway')
        form.add_field(:delivery_number, 'Delivery', scan: 'key248_all', scan_type: :delivery)
        form.add_field(:sku_number, 'SKU', scan: 'key248_all', scan_type: :sku)
        form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, lookup: true)
        form.add_field(:quantity, 'Quantity', data_type: 'number')
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do        # CREATE
        interactor = PackMaterialApp::MrDeliveryInteractor.new(current_user, {}, { route_url: request.path }, {})
        res = interactor.putaway_delivery(params[:putaway])
        payload = { progress: nil }
        if res.success
          payload[:delivery_id] = res.instance[:delivery_id]
          payload[:progress] = res.instance[:report]
        else
          these_params = params[:putaway]
          payload[:error_message] = res.message
          payload[:errors] = res.errors
          payload.merge!(location: these_params[:location],
                         location_scan_field: these_params[:location_scan_field],
                         sku_number: these_params[:sku_number],
                         sku_number_scan_field: these_params[:sku_number_scan_field],
                         delivery_number: these_params[:delivery_number],
                         delivery_number_scan_field: these_params[:delivery_number_scan_field],
                         quantity: these_params[:quantity])
        end

        store_locally(:delivery_putaway, payload)
        r.redirect '/rmd/deliveries/putaways/new'
      end
    end

    r.on 'status' do
      view(inline: '<h2>Just a dummy page this...</h2><p>Nothing to see here, keep moving along...</p>', layout: :layout_rmd)
    end
  end
end
