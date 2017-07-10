module Label
  class Properties
    def self.call(id, form_values = nil, form_errors = nil)
      this_repo = LabelRepo.new(DB.db)
      obj       = this_repo.labels.by_pk(id).one
      rules = { fields: {
        label_name: { },
        label_dimension: { renderer: :select,
                           options: ['8464', 'A4', 'A5', 'Custom'] },
      } } #, name: 'label'.freeze }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object obj
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action "/label_designer/#{id}/update"
          form.add_field :label_name
          form.add_field :label_dimension
        end
      end

      layout
    end
  end
end
