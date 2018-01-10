module LabelView
  class New
    def self.call(form_values: nil, form_errors: nil, remote: true)
      print_repo = PrinterRepo.new
      repo = MasterListRepo.new
      rules = { fields: {
        label_name: { maxlength: 16, pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces' },
        label_dimension: { renderer: :select,
                           options: %w[8464 A4 A5 Custom] },
        px_per_mm: { renderer: :select,
                     options: print_repo.distinct_px_mm,
                     caption: 'Resolution (px/mm)' },
        container_type: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'container_type' }) },
        commodity: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'commodity' }) },
        market: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'market' }) },
        language: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'language' }) },
        category: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'category' }) },
        sub_category: { renderer: :select, options: repo.for_select_master_lists(where: { list_type: 'sub_category' }) }
      }, name: 'label'.freeze }

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object(OpenStruct.new(label_name: nil,
                                        label_dimension: nil,
                                        px_per_mm: nil))
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action '/label_designer/create'
          form.remote! if remote
          form.add_field :label_name
          form.add_field :label_dimension
          form.add_field :px_per_mm
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
