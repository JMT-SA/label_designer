# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class Publish
        def self.call(current_step)
          desc = ["Printer: #{current_step[:printer_type]}", "Targets: #{current_step[:targets].join(', ')}", "#{current_step[:label_ids].length} Labels"] # Use text desc of choices...

          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.section do |section|
              section.add_progress_step ['Select target destinations', 'Select labels', 'Publish'], position: 2, state_description: desc
              section.show_border!
            end
            page.callback_section do |section|
              section.caption = 'Assemble and send to publishing server'
              section.url = '/labels/publish/batch/send'
            end
          end

          layout
        end
      end
    end
  end
end
