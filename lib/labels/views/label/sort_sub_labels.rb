# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class SortSubLabels
        def self.call(id, sub_label_ids)
          repo = LabelApp::LabelRepo.new
          label_list = repo.sub_label_list(sub_label_ids)

          layout = Crossbeams::Layout::Page.build do |page|
            page.form do |form|
              form.action "/labels/labels/labels/#{id}/apply_sub_labels"
              form.remote!
              form.add_text 'Drag and drop to set the label order. Press submit to save the new order.'
              form.add_sortable_list('sublbl', label_list)
            end
          end

          layout
        end
      end
    end
  end
end
