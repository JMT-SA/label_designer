# frozen_string_literal: true

module UiRules
  class MasterListRule < Base
    def generate_rules
      @repo = LabelApp::MasterListRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'master_list'
    end

    def set_show_fields
      fields[:list_type] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        # list_type: { renderer: :select, options: list_types },
        list_type: { readonly: true },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_master_list(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(list_type: nil,
                                    description: nil)
    end

    # def list_types
    #   %w[container_type commodity market language category sub_category]
    # end
  end
end
