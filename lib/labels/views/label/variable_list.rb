# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class VariableList
        extend LabelVariableFields

        def self.call(id, remote: true)
          label, rules, xml_vars = vars_for_label(id, as_labels: true) do |rule_base|
            rule_base[:fields] = {}
            rule_base[:name] = 'label'
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object OpenStruct.new(label_name: label.label_name)
            page.form do |form|
              form.view_only!
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
