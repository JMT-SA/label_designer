# require './lib/labels/repositories/label_repo.rb'
module LabelView
  class Properties
    def self.call(id, form_values = nil, form_errors = nil)
      this_repo = LabelRepo.new
      repo      = MasterListRepo.new
      obj       = this_repo.find_labels(id)
      rules = { fields: {
        label_name: { maxlength: 16, pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces' },
        container_type: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'container_type' }) },
        commodity: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'commodity' }) },
        market: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'market' }) },
        language: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'language' }) },
        category: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'category' }) },
        sub_category: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'sub_category' }) }
      } }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object obj
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action "/label_designer/#{id}/update"
          form.remote!
          form.add_field :label_name
          form.add_field :container_type
          form.add_field :commodity
          form.add_field :market
          form.add_field :language
          form.add_field :category
          form.add_field :sub_category
        end
      end

      layout
    end
  end
end
