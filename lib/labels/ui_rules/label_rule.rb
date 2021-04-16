# frozen_string_literal: true

module UiRules
  class LabelRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @this_repo = LabelApp::LabelRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      @master_repo = LabelApp::MasterListRepo.new
      @user_repo = DevelopmentApp::UserRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_properties_fields if @mode == :properties
      set_show_fields if %i[show archive reopen].include? @mode
      set_complete_fields if @mode == :complete
      set_approve_fields if @mode == :approve
      set_import_fields if @mode == :import

      add_approve_behaviours if @mode == :approve
      extended_columns(@this_repo, :labels, edit_mode: !%i[show archive complete reopen].include?(@mode))

      form_name 'label'
    end

    def set_properties_fields
      fields[:variable_set] = AppConst::LABEL_VARIABLE_SETS.length == 1 ? { renderer: :hidden } : { renderer: :label }
      fields[:print_rotation] = {
        renderer: :select,
        options: [['None', 0], ['Right', 90], ['Left', -90]],
        required: true,
        sort_items: false,
        hint: '<p>When printing, rotate the label design from horizontal to vertical.</p><p>Choose "Right" to rotate clockwise (90&deg;) and "Left" to rotate anti-clockwise (-90&deg;).</p>'
      }
    end

    def set_approve_fields
      set_show_fields
      fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
      fields[:reject_reason] = { renderer: :textarea, disabled: true }
    end

    def set_complete_fields
      set_show_fields
      fields[:to] = { renderer: :select, options: @user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_LABEL_APPROVERS), caption: 'Email address of person to notify', required: true }
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:label_name] = { renderer: :label }
      fields[:label_dimension] = { renderer: :label }
      fields[:px_per_mm] = { renderer: :label }
      fields[:container_type] = { renderer: :label }
      fields[:commodity] = { renderer: :label }
      fields[:market] = { renderer: :label }
      fields[:language] = { renderer: :label }
      fields[:category] = { renderer: :label }
      fields[:sub_category] = { renderer: :label }
      fields[:variable_set] = AppConst::LABEL_VARIABLE_SETS.length == 1 ? { renderer: :hidden } : { renderer: :label }
      fields[:print_rotation] = { renderer: :label, with_value: rotation_string }
    end

    def set_import_fields
      fields[:import_file] = { renderer: :file, accept: '.ldexport', required: true }
    end

    def common_fields
      variable_set_rule = if AppConst::LABEL_VARIABLE_SETS.length == 1
                            { renderer: :hidden }
                          else
                            { renderer: :select,
                              options: AppConst::LABEL_VARIABLE_SETS,
                              required: true }
                          end

      {
        label_name: { pattern: :no_spaces, pattern_msg: 'Label name cannot include spaces', required: true },
        label_dimension: { renderer: :select,
                           options: AppConst::LABEL_SIZES.keys.sort, required: true },
        px_per_mm: { renderer: :select,
                     options: @print_repo.distinct_px_mm,
                     caption: 'Resolution (px/mm)', required: true },
        container_type: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'container_type' }), required: true },
        commodity: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'commodity' }), required: true },
        market: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'market' }), required: true },
        language: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'language' }), required: true },
        category: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'category' }) },
        sub_category: { renderer: :select, options: @master_repo.for_select_master_lists(where: { list_type: 'sub_category' }) },
        multi_label: { renderer: :checkbox },
        variable_set: variable_set_rule,
        print_rotation: {
          renderer: :select,
          options: [['None', 0], ['Right', 90], ['Left', -90]],
          required: true,
          sort_items: false,
          hint: '<p>When printing, rotate the label design from horizontal to vertical.</p><p>Choose "Right" to rotate clockwise (90&deg;) and "Left" to rotate anti-clockwise (-90&deg;).</p>'
        }
      }
    end

    def make_form_object
      if @mode == :new || @mode == :import
        make_new_form_object
        return
      end

      @form_object = @this_repo.find_label(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge(to: nil)) if @mode == :complete
      @form_object = OpenStruct.new(@form_object.to_h.merge(approve_action: nil, reject_reason: nil)) if @mode == :approve
    end

    def make_new_form_object
      @form_object = OpenStruct.new(label_name: nil,
                                    label_dimension: AppConst::DEFAULT_LABEL_DIMENSION,
                                    px_per_mm: '8',
                                    container_type: nil,
                                    commodity: nil,
                                    market: nil,
                                    language: nil,
                                    category: nil,
                                    sub_category: nil,
                                    multi_label: false,
                                    print_rotation: 0,
                                    variable_set: AppConst::LABEL_VARIABLE_SETS.first)
      apply_extended_column_defaults_to_form_object(:labels)
    end

    private

    def add_approve_behaviours
      behaviours do |behaviour|
        behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
      end
    end

    def rotation_string
      case @form_object.print_rotation
      when 90
        'Right'
      when -90
        'Left'
      else
        ''
      end
    end
  end
end
