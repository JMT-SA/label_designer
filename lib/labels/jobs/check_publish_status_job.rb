# frozen_string_literal: true

module LabelApp
  class CheckPublishStatusJob < BaseQueJob # rubocop:disable Metrics/ClassLength
    def run(user_id, label_publish_log_id) # rubocop:disable Metrics/AbcSize
      lookup_label_publish_log(label_publish_log_id)
      lookup_user_name(user_id)

      # Should only do if not retry (i.e. first call)
      sleep(1)
      res = publish_labels_status

      if response_is_200_or_204(res) # res.success && res.instance[:response_code].to_s != '204'
        handle_success(res.instance)
      elsif res.instance[:response_code].to_s.start_with?('404') || res.instance[:response_code].to_s.start_with?('204') # Nothing sent from MesServer to CMS/MesScada yet...
        handle_retry
      else
        handle_fail(res)
      end
    end

    private

    def response_is_200_or_204(res)
      return false unless res.success
      return false if res.instance&.is_a?(Hash) && res.instancee[:response_code].to_s == '204'

      true
    end

    def handle_success(instance)
      labels = @repo.published_label_lookup(@label_publish_log.id)
      @repo.transaction do
        if apply_log_changes(labels, instance)
          notify_apps_of_publishing
          finish
        else
          retry_in(0.2)
        end
      end
    end

    def handle_retry
      # Give up after 45 seconds without an answer.
      # This kludge to get around some UTC/SAST issues - created_at should be stored as UTC, not without zone...
      diff = (Time.now.getutc.to_i - @label_publish_log.created_at.to_i)
      diff -= 7200 if diff > 7200
      # if (Time.now.utc - @label_publish_log.created_at.utc) > 45
      if diff > 45
        @repo.update(:label_publish_logs, @label_publish_log.id, failed: true, status: 'NOT_FOUND', errors: 'MesServer failed to respond', complete: true)
        expire
      else
        retry_in(0.2)
      end
    end

    def handle_fail(res)
      msg = if res.instance[:timeout]
              'Timeout'
            elsif res.instance[:refused]
              'Connection refused'
            else
              res.message
            end
      @repo.update(:label_publish_logs, @label_publish_log.id, failed: true, status: 'FAILED', errors: msg, complete: true)
      finish
    end

    def lookup_label_publish_log(label_publish_log_id)
      @repo = LabelApp::LabelRepo.new
      @label_publish_log = @repo.find_label_publish_log(label_publish_log_id)
    end

    def lookup_user_name(user_id)
      user = DevelopmentApp::UserRepo.new.find_user(user_id)
      @user_name = user.user_name
    end

    def publish_labels_status
      mes_repo = MesserverApp::MesserverRepo.new
      mes_repo.send_publish_status(@label_publish_log.printer_type, @label_publish_log.publish_name)
    end

    # messerver states includes local and remote publishing targets.
    # The local ones match to log records, the remote are "incidental"
    def apply_log_changes(labels, messerver_states) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      details = @repo.all(:label_publish_log_details, LabelApp::LabelPublishLogDetail, label_publish_log_id: @label_publish_log.id)
      # {"Data"=>[{"File"=>"MAIN_BIN.zip", "Status"=>"200 OK", "To"=>"10.0.6.6", "PrinterType"=>"Local", "Date"=>"zebra", "Time"=>"12-24-2019"}]}
      # {"Data"=>[{"File"=>"MAIN_BIN.zip", "Status"=>"200 OK", "To"=>"10.0.6.6", "Module"=>"MES-01", "Location"=>"Local", "PrinterType"=>"zebra", "Date"=>"12-26-2019", "Time"=>65251}]}

      failed_remotes = []
      passed_remotes = []
      server_states = []
      messerver_states.each do |state|
        if state['Location'] && state['Location'] != 'Local' # add these to main log...
          if state['Status'].start_with?('200')
            passed_remotes << "MODULE: #{state['Module']} - IP: #{state['To']}"
          else
            failed_remotes << "MODULE: #{state['Module']} - IP: #{state['To']} - #{state['Status']}"
          end
          next
        end

        key = state['File'].delete_suffix('.zip')
        label_id = labels[key]
        match_detail = details.find { |d| d.label_id == label_id && d.server_ip.to_s == state['To'] }
        raise "Could not find match: #{label_id} / #{state['To']} .. #{state.inspect} .. #{details.inspect}" if match_detail.nil?
        next if match_detail.complete

        if state['Status'].start_with?('200')
          @repo.update_label_publish_log_detail(match_detail.id, complete: true, status: 'PUBLISHED')
          # status for lbl
          @repo.log_status(:labels, label_id, 'PUBLISHED', comment: "to #{match_detail.server_ip}", user_name: @user_name)
          server_states << "#{state['Module']} (#{state['To']}) - OK"
        else
          @repo.update_label_publish_log_detail(match_detail.id, complete: true, failed: true, errors: state['Status'], status: 'FAILED TO PUBLISH')
          @repo.log_status(:labels, label_id, 'FAILED TO PUBLISH', comment: "to #{match_detail.server_ip}", user_name: @user_name)
          server_states << "#{state['Module']} (#{state['To']}) - #{state['Status']}"
        end
      end
      summary = ["Published to #{server_states.length} server#{server_states.length == 1 ? '' : 's'}"]
      summary << "and to #{passed_remotes.length} out of #{passed_remotes.length + failed_remotes.length} remote modules" unless failed_remotes.empty? && passed_remotes.empty?
      details = {
        failed_remotes: failed_remotes,
        passed_remotes: passed_remotes,
        server_states: server_states,
        summary: summary.join(' ')
      }

      complete, failed = @repo.published_label_conditions(@label_publish_log.id)
      if complete
        @repo.update(:label_publish_logs, @label_publish_log.id, failed: failed, status: 'PUBLISHED', complete: true, publish_summary: @repo.hash_for_jsonb_col(details))
      else
        @repo.update(:label_publish_logs, @label_publish_log.id, publish_summary: @repo.hash_for_jsonb_col(details))
      end
      complete
    end

    def notify_apps_of_publishing
      return if AppConst::LABEL_PUBLISH_NOTIFY_URLS.empty?

      BroadcastLabelPublishEventJob.enqueue(@label_publish_log.id)
    end
  end
end
