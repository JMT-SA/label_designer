# frozen_string_literal: true

module Labels
  module Publish
    module Publish
      class Summary
        def self.call(id) # rubocop:disable Metrics/AbcSize
          summary = BaseRepo.new.find_hash(:label_publish_logs, id)[:publish_summary]

          layout = Crossbeams::Layout::Page.build({}) do |page|
            if summary.nil?
              page.add_notice 'There is no summary data'
            else
              page.add_text summary['summary']
              page.add_notice summary['server_states'].join('<br>'), caption: 'Server'
              page.add_notice summary['failed_remotes'].join('<br>'), notice_type: :warning, caption: 'Failed to publish to these remote modules' unless summary['failed_remotes'].empty?
              page.add_notice summary['passed_remotes'].join('<br>'), notice_type: :success, caption: 'Published to these remote modules' unless summary['passed_remotes'].empty?
            end
          end

          layout
        end
      end
    end
  end
end
