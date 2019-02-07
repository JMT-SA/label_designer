# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Reopen
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:label, :reopen, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.remote!
              form.action "/labels/labels/labels/#{id}/reopen"
              form.submit_captions 'Reopen'
              form.add_text 'Are you sure you want to reopen this label for editing?', wrapper: :h3
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
