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
              # form.add_text 'Are you sure you want to complete this label?', wrapper: :h3
              # form.add_field :to
              form.add_field :approve_action
              form.add_field :reject_reason
              form.add_field :label_name
              form.add_field :container_type
              form.add_field :commodity
              form.add_field :market
              form.add_field :language
              form.add_field :category
              form.add_field :sub_category
            end
          end

          layout
        end
      end
    end
  end
end