# frozen_string_literal: true

module LabelApp
  class NotifyLabelPublishEventJob < BaseQueJob
    def run(label_publish_notification_id, payload)
      lookup_label_publish_notification(label_publish_notification_id)

      res = make_notification(payload)

      if res.success
        log_success
      else
        log_failure(res)
      end
      finish
    end

    private

    def lookup_label_publish_notification(id)
      @repo = LabelApp::LabelRepo.new
      @instance = @repo.find_label_publish_notification(id)
    end

    def make_notification(payload)
      url = @instance.url
      http = Crossbeams::HTTPCalls.new
      http.json_post(url, publish_data: payload)
    end

    def log_success
      @repo.update_label_publish_notification(@instance.id, complete: true)
    end

    def log_failure(res)
      @repo.update_label_publish_notification(@instance.id, complete: true, failed: true, errors: res.message)
    end
  end
end
