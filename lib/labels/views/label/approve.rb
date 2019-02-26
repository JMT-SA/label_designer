# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Approve
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:label, :approve, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.remote!
              form.action "/labels/labels/labels/#{id}/approve"
              form.submit_captions 'Approve or Reject'
              form.add_field :approve_action
              form.add_field :reject_reason
              form.add_field :label_name
              form.fold_up do |fold|
                fold.add_field :container_type
                fold.add_field :commodity
                fold.add_field :market
                fold.add_field :language
                fold.add_field :category
                fold.add_field :sub_category
              end
            end
          end

          layout
        end
      end
    end
  end
end
