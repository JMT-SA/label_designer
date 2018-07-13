# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class Targets
        def self.call
          # ui_rule = UiRules::Compiler.new(:printer, :show, id: id)
          # rules   = ui_rule.compile
          rules = {}

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_progress_step ['Select target destinations', 'Select labels', 'Publish']
              section.show_border!
            end
            # test_descs = ['Printer: Argox', 'Destination: moon']
            # # test_descs = 'Printer: Argox'
            # # test_descs = nil
            # page.section do |section|
            #   section.show_border!
            #   section.add_progress_step %w[first second third fourth fifth sixth seventh eighth]
            # end
            # page.section do |section|
            #   section.show_border!
            #   section.add_progress_step %w[first second third fourth], position: 1
            # end
            # page.section do |section|
            #   section.show_border!
            #   section.add_progress_step %w[first second third fourth], position: 2, state_description: test_descs
            # end
            # page.section do |section|
            #   section.show_border!
            #   section.add_progress_step %w[first second third fourth], position: 3, state_description: test_descs
            # end
            # page.section do |section|
            #   section.show_border!
            #   section.add_progress_step %w[first second third fourth], position: 4, show_finished: true, state_description: test_descs
            # end
            page.callback_section do |section|
              section.caption = 'Select target destinations'
              section.url = '/labels/publish/batch/show_targets'
            end
          end

          layout
        end
      end
    end
  end
end
