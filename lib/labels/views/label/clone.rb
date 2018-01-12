# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Clone
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:label, :clone, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/labels/labels/labels/#{id}/clone_label"
              form.remote! if remote
              form.add_field :label_name
            end
          end

          layout
        end
      end
    end
  end
end
