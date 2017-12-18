# require './lib/labels/repositories/label_repo.rb'
module LabelView
  class Properties
    def self.call(id, form_values = nil, form_errors = nil)
      this_repo = LabelRepo.new
      obj       = this_repo.find_labels(id)
      rules = { fields: {
        label_name: { pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces' }
      } }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object obj
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action "/label_designer/#{id}/update"
          form.remote!
          form.add_field :label_name
        end
      end

      layout
    end
  end
end
