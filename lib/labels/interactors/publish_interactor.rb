# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module LabelApp
  class PublishInteractor < BaseInteractor
    def repo
      @repo ||= LabelRepo.new
    end

    def stepper
      @stepper ||= PublishStep.new(@user)
    end

    def publishing_server_options
      res = LabelApp::MesServerRepo.new.publish_target_list
      return failed_response(res.message) unless res.success

      lkps = Hash[res.instance.map { |a| [a['NetworkInterface'], { name: a['Alias'], printers: a['PrinterTypes'] }] }]
      printer_types = res.instance.map { |i| i['PrinterTypes'] }.flatten.uniq.sort
      targets = lkps.map { |k, v| [v[:name], k] } # res.instance.map { |i| [i['Alias'], i['NetworkInterface']] }.sort
      stepper.write(printer_types: printer_types, targets: targets, lookup: lkps)
      success_response('OK', printer_types: printer_types, targets: targets)
    end

    def select_targets(params)
      current = stepper.read
      stepper.write(current.merge(chosen_printer: params[:printer_type], chosen_targets: params[:target_destinations]))
      success_response('ok', stepper)
    end

    def save_label_selections(ids)
      # store = LocalStore.new(current_user.id)
      # current = store.read(:lbl_publish_steps)
      stepper.merge(label_ids: ids)
      success_response('ok', stepper)
    end

    def publish_labels # (vars)
      vars = stepper.read
      # {:printer_type=>"Datamax", :targets=>["192.168.50.201", "192.168.50.200"], :label_ids=>[5, 6, 23]}
      # instance = label(id)
      # Store the input variables:
      # repo.update_label(id, sample_data: repo.hash_to_jsonb_str(vars))
      # TODO: store history of publishing...

      fname, binary_data = LabelFiles.new.make_combined_zip(vars[:label_ids])
      # File.open('zz.zip', 'w') { |f| f.puts binary_data }

      mes_repo = MesServerRepo.new
      res = mes_repo.send_publish_package(vars[:chosen_printer], vars[:chosen_targets], fname, binary_data)
      if res.success
        success_response('Published labels.', OpenStruct.new(fname: fname, body: res.instance))
      else
        failed_response(res.message)
      end
    end

    def publishing_status # (vars)
      vars = stepper.read
      mes_repo = MesServerRepo.new
      res = mes_repo.send_publish_status(vars[:chosen_printer], LabelFiles.new.combined_zip_filename)
      if res.success
        # TODO: use step wrapper to do formatting
        success_response('Published labels.', OpenStruct.new(done: all_published?(vars, res.instance), body: publishing_table(vars, res.instance))) # decide on done...
      elsif res.instance == '404' # Nothing sent yet...
        success_response('Published labels.', OpenStruct.new(done: false, body: publishing_table(vars, [])))
      else
        failed_response(res.message, res.instance) # instance is response code
      end
    end

    def all_published?(vars, response_body)
      expected = vars[:chosen_targets].length * vars[:label_ids].length
      response_body.length == expected && response_body.all? { |item| !item['Status'].nil? }
    end

    def publishing_table(vars, response_body)
      lkp = publishing_table_lookup(response_body)
      # cols = vars[:targets].map { |t| vars[:lookup][t][:name] }.sort.unshift('Label')
      cols = vars[:chosen_targets].sort.unshift('Label')
      rows = publishing_table_rows(lkp)
      # Placeholders for not-sent labels...
      publishing_table_add_missing_rows(rows, vars, lkp)
      Crossbeams::Layout::Table.new({}, rows, cols, cell_classes: publishing_table_classes(vars[:chosen_targets])).render
    end

    def publishing_table_add_missing_rows(rows, vars, lkp)
      # ((vars[:label_ids].length + 1) - lkp.keys.length).times { rows << { 'Label' => '...', '192.168.50.200' => '500 Dummy err' } }
      (vars[:label_ids].length - lkp.keys.length).times { rows << { 'Label' => '...', '192.168.50.200' => '500 Dummy err' } }
    end

    def publishing_table_classes(targets)
      rules = {}
      targets.each do |target|
        rules[target] = ->(status) { status.to_s.include?('200') ? 'green' : 'red' }
      end
      rules
    end

    def publishing_table_rows(lkp)
      lkp.keys.map do |key|
        { 'Label' => key }.merge(lkp[key])
      end
    end

    def publishing_table_lookup(response_body)
      lkp = {}
      response_body.each do |item|
        key = item['File'].sub('.zip', '')
        lkp[key] ||= {}
        lkp[key][item['To']] = item['Status']
      end
      lkp
    end
  end
end
# rubocop:enable Metrics/ClassLength
