module Label
  class Clone
    def self.call(id)

      this_repo = LabelRepo.new(DB.db)
      obj       = this_repo.labels.by_pk(id).one
      rules = { fields: {
        label_name: { },
        label_dimension: { renderer: :select,
                           options: ['8464', 'A4', 'A5', 'Custom'] },
        cloned: { renderer: :hidden },
      }, name: 'label'.freeze }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object obj
        page.form_values cloned: 'y'
        page.form do |form|
          form.action '/label_designer/create'
          form.add_field :label_name
          form.add_field :label_dimension
          form.add_field :cloned
        end
      end

      layout
    end
  end
end
