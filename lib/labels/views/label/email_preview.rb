# frozen_string_literal: true

require_relative 'label_variable_fields'

module Labels
  module Labels
    module Label
      class EmailPreview
        extend LabelVariableFields

        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          label, rules, xml_vars = vars_for_label(id) do |rule_base|
            rule_base[:fields] = {
              to: { renderer: :email, required: true }, # email type does not allow for more than one...Need a control for this
              cc: { caption: 'CC (as well as yourself)' },
              subject: { required: true },
              body: { renderer: :textarea, required: true }
            }
            rule_base[:name] = 'label'
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object OpenStruct.new(label.sample_data || {})
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/labels/labels/labels/#{id}/email_preview"
              form.remote! if remote
              form.method :update
              form.add_field :to
              form.add_field :cc
              form.add_field :subject
              form.add_field :body
              form.add_text 'Label variables', wrapper: :b
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
