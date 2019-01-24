# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class Publish
        def self.call(current_step)
          desc = current_step.step_3_desc

          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.section do |section|
              section.add_progress_step ['Select target destinations', 'Select labels', 'Publish'], position: 2, state_description: desc
              section.show_border!
            end
            page.callback_section do |section|
              section.caption = 'Assemble and send to publishing server'
              section.url = '/labels/publish/batch/callback_for_send'
            end
          end

          layout
        end
      end
    end
  end
end
