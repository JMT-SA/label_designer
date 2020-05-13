# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class BatchPrint
        extend LabelVariableFields

        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          this_repo = LabelApp::LabelRepo.new
          repo      = LabelApp::PrinterRepo.new
          obj       = this_repo.find_label(id)
          printers  = repo.printers_for(obj.px_per_mm)
          label, rules, xml_vars = vars_for_label(id) do |rule_base|
            rule_base[:fields] = {
              no_of_labels: { renderer: :integer, required: true },
              printer: { renderer: :select,
                         options: printers,
                         caption: 'Printer',
                         required: true }
            }
            rule_base[:name] = 'label'
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object OpenStruct.new(label.sample_data || {})
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/labels/labels/labels/#{id}/batch_print"
              form.remote! if remote
              form.method :update
              form.add_field :no_of_labels
              form.add_field :printer
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
