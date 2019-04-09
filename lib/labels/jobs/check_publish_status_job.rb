# frozen_string_literal: true

module LabelApp
  class CheckPublishStatusJob < BaseQueJob
    def run(user_id, label_publish_log_id)
      lookup_label_publish_log(label_publish_log_id)
      lookup_user_name(user_id)

      res = publish_labels_status

      if res.success
        handle_success(res.instance)
      elsif res.instance[:response_code].to_s.start_with?('404') # Nothing sent from MesServer to CMS/MesScada yet...
        handle_retry
      else
        handle_fail(res)
      end
    end

    private

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
      if (Time.now - @label_publish_log.created_at) > 45
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

    def apply_log_changes(labels, messerver_states) # rubocop:disable Metrics/AbcSize
      details = @repo.all(:label_publish_log_details, LabelApp::LabelPublishLogDetail, label_publish_log_id: @label_publish_log.id)

      messerver_states.each do |state|
        key = state['File'].delete_suffix('.zip')
        label_id = labels[key]
        match_detail = details.find { |d| d.label_id == label_id && d.server_ip.to_s == state['To'] }
        raise "Could not find match: #{label_id} / #{state['To']} .. #{state.inspect} .. #{details.inspect}" if match_detail.nil?
        next if match_detail.complete
        if state['Status'].start_with?('200')
          @repo.update_label_publish_log_detail(match_detail.id, complete: true, status: 'PUBLISHED')
          # status for lbl
          @repo.log_status(:labels, label_id, 'PUBLISHED', comment: "to #{match_detail.server_ip}", user_name: @user_name)
        else
          @repo.update_label_publish_log_detail(match_detail.id, complete: true, failed: true, errors: state['Status'], status: 'FAILED TO PUBLISH')
          @repo.log_status(:labels, label_id, 'FAILED TO PUBLISH', comment: "to #{match_detail.server_ip}", user_name: @user_name)
        end
      end

      complete, failed = @repo.published_label_conditions(@label_publish_log.id)
      if complete
        @repo.update(:label_publish_logs, @label_publish_log.id, failed: failed, status: 'PUBLISHED', complete: true)
      end
      complete
    end

    def notify_apps_of_publishing
      return if AppConst::LABEL_PUBLISH_NOTIFY_URLS.empty?
      BroadcastLabelPublishEventJob.enqueue(@label_publish_log.id)
    end
  end
end
