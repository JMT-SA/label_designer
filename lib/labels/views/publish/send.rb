# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class Send
        def self.call(res)
          layout = Crossbeams::Layout::Page.build({}) do |page|
            if res.success
              page.add_repeating_request('/labels/publish/batch/feedback', 1000, 'Labels have been sent for publishing, awaiting confirmation')
            else
              page.add_text("FAILED: #{res.message}")
            end
          end

          layout
        end
      end
    end
  end
end
