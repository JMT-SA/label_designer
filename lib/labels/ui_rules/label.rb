# frozen_string_literal: true

module UiRules
  class LabelRule < Base
    def generate_rules
      @this_repo = LabelRepo.new
      @print_repo = PrinterRepo.new
      @master_repo = MasterListRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'label'
    end

    def set_show_fields
      fields[:label_name] = { renderer: :label }
      fields[:label_dimension] = { renderer: :label }
      fields[:px_per_mm] = { renderer: :label }
      fields[:container_type] = { renderer: :label }
      fields[:commodity] = { renderer: :label }
      fields[:market] = { renderer: :label }
      fields[:language] = { renderer: :label }
      fields[:category] = { renderer: :label }
      fields[:sub_category] = { renderer: :label }
    end

    def common_fields
      {
        label_name: { maxlength: 16, pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces' },
        label_dimension: { renderer: :select,
                           options: LabelDesigner::LABEL_SIZES.keys.sort },
        px_per_mm: { renderer: :select,
                     options: @print_repo.distinct_px_mm,
                     caption: 'Resolution (px/mm)' },
        container_type: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'container_type' }) },
        commodity: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'commodity' }) },
        market: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'market' }) },
        language: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'language' }) },
        category: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'category' }) },
        sub_category: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'sub_category' }) },
        multi_label: { renderer: :checkbox }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_label(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(label_name: nil,
                                    label_dimension: '8464',
                                    px_per_mm: '8',
                                    container_type: nil,
                                    commodity: nil,
                                    market: nil,
                                    language: nil,
                                    category: nil,
                                    sub_category: nil,
                                    multi_label: false)
    end
  end
end
