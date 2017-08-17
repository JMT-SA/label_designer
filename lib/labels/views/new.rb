module LabelView
  class New
    def self.call(form_values = nil, form_errors = nil)

      rules = { fields: {
        label_name: { pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces' },
        label_dimension: { renderer: :select,
                           options: ['8464', 'A4', 'A5', 'Custom'] },
      }, name: 'label'.freeze }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object(OpenStruct.new(label_name: nil,
                                        label_dimension: nil))
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action '/label_designer/create'
          form.add_field :label_name
          form.add_field :label_dimension
        end
      end

      layout
    end
  end
end
