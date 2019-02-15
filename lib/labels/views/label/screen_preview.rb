# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class ScreenPreview
        extend LabelVariableFields

        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          label, rules, xml_vars = vars_for_label(id) do |rule_base|
            rule_base[:fields] = {}
            rule_base[:name] = 'label'
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object OpenStruct.new(label.sample_data || {})
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/labels/labels/labels/#{id}/send_preview/screen"
              form.remote! if remote
              xml_vars.each do |v|
                form.add_field v.to_sym
              end
            end
          end

          layout
        end
      end
    end
  end
end
