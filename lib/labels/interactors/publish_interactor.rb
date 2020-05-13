# frozen_string_literal: true

module LabelApp
  class PublishInteractor < BaseInteractor
    def repo
      @repo ||= LabelRepo.new
    end

    def stepper
      @stepper ||= PublishStep.new(@user)
    end

    def publishing_server_options # rubocop:disable Metrics/AbcSize
      res = MesserverApp::MesserverRepo.new.publish_target_list
      return failed_response(res.message, res.instance) unless res.success

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

    def publish_labels # rubocop:disable Metrics/AbcSize
      vars = stepper.read
      # {:printer_type=>"Datamax", :targets=>["192.168.50.201", "192.168.50.200"], :label_ids=>[5, 6, 23]}

      begin
        fname, binary_data = LabelFiles.new.make_combined_zip(vars[:label_ids])
      rescue Crossbeams::FrameworkError => e
        return failed_response(e.message)
      end
      # File.open('zz.zip', 'w') { |f| f.puts binary_data }

      # JS: create publish header & publish_label_logs
      create_publish_logs(fname, vars)
      clear_published_history(vars[:label_ids])

      mes_repo = MesserverApp::MesserverRepo.new
      res = mes_repo.send_publish_package(vars[:chosen_printer], vars[:chosen_targets], fname, binary_data)
      if res.success
        success_response('Published labels.', OpenStruct.new(fname: fname, body: res.instance))
      else
        failed_response(res.message)
      end
    end

    def clear_published_history(label_ids)
      label_ids.each do |label_id|
        DevelopmentApp::ClearAuditTrail.enqueue(:labels, label_id, keep_latest: true)
      end
    end

    def create_publish_logs(fname, vars) # rubocop:disable Metrics/AbcSize
      printer = vars[:chosen_printer]
      targets = vars[:targets].select { |t| vars[:chosen_targets].include?(t.last) }

      # read labels & create for each...
      repo.transaction do
        id = repo.create(:label_publish_logs,
                         user_name: @user.user_name,
                         printer_type: printer,
                         publish_name: fname,
                         status: 'PUBLISHING')

        targets.each do |dest, ip|
          vars[:label_ids].each do |label_id|
            repo.create(:label_publish_log_details,
                        label_publish_log_id: id,
                        label_id: label_id,
                        server_ip: ip,
                        destination: dest,
                        status: 'PUBLISHING')
          end
        end

        stepper.merge(label_publish_log_id: id)

        LabelApp::CheckPublishStatusJob.enqueue(@user.id, id)
      end
    end

    def publishing_status # rubocop:disable Metrics/AbcSize
      vars = stepper.read
      log = repo.find_label_publish_log(vars[:label_publish_log_id])
      label_states = repo.label_publish_states(log.id)
      success_response('Published labels', OpenStruct.new(done: log.complete,
                                                          failed: log.failed,
                                                          errors: log.errors,
                                                          chosen_printer: vars[:chosen_printer],
                                                          publish_summary: log.publish_summary,
                                                          body: label_states))
    end
  end
end
