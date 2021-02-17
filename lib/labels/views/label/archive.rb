# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Archive
        def self.call(id, un_archive: false, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:label, :archive, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.remote!
              if un_archive
                form.action "/labels/labels/labels/#{id}/un_archive"
                form.submit_captions 'Un-Archive this label'
                form.add_text 'Are you sure you want to un-archive this label?', wrapper: :h3
              else
                form.action "/labels/labels/labels/#{id}/archive"
                form.submit_captions 'Archive this label'
                form.add_text 'Are you sure you want to archive this label?', wrapper: :h3
              end
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
  end
end
