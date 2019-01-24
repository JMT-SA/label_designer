# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class Targets
        def self.call
          # TODO: if back, add back=y to callback url
          rules = {}

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_progress_step ['Select target destinations', 'Select labels', 'Publish']
              section.show_border!
            end
            page.callback_section do |section|
              section.caption = 'Select target destinations'
              section.url = '/labels/publish/batch/callback_for_targets'
            end
          end

          layout
        end
      end
    end
  end
end
