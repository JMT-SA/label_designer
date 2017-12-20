module LabelView
  class Clone
    def self.call(id)
      this_repo = LabelRepo.new
      obj       = this_repo.find_labels(id)
      rules = { fields: {
        label_name: { pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces' },
        id: { renderer: :hidden }
      } }

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
