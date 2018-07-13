# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class SelectLabels
        def self.call(current_step)
          # ui_rule = UiRules::Compiler.new(:label_publish, :select_labels)
          # rules   = ui_rule.compile
          rules = {}

          desc = ["Printer: #{current_step[:printer_type]}", "Targets: #{current_step[:targets].join(', ')}"] # Use text desc of choices...

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_progress_step ['Select target destinations', 'Select labels', 'Publish'], position: 1, state_description: desc
              section.show_border!
            end
            page.section do |section|
              section.add_grid('lbl_grid',
                               '/list/labels_for_publishing/grid_multi/standard',
                               caption: 'Choose Labels',
                               is_multiselect: true,
                               multiselect_url: '/labels/publish/batch/publish',
                               multiselect_key: 'standard',
                               multiselect_params: {})
            end
          end

          layout
        end
      end
    end
  end
end
