module Label
  class Clone
    def self.call(id)

      this_repo = LabelRepo.new(DB.db)
      obj       = this_repo.labels.by_pk(id).one
      rules = { fields: {
        label_name: { },
        id: { renderer: :hidden },
      }, name: 'label'.freeze }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object obj
        page.form do |form|
          form.action "/label_designer/#{id}/clone_label"
          form.add_field :label_name
          form.add_field :id
        end
      end

      layout
    end
  end
end
