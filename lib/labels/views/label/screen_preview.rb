# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class ScreenPreview
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          rules, xml_vars = rules_and_fields(id)

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object OpenStruct.new
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/labels/labels/labels/#{id}/send_preview/screen"
              form.remote! if remote
              xml_vars.each do |v|
                form.add_field v.to_sym
              end
            end
          end

          layout
        end

        def self.rules_and_fields(id) # rubocop:disable Metrics/AbcSize
          this_repo = LabelRepo.new
          obj       = this_repo.find_label(id)
          doc       = Nokogiri::XML(obj.variable_xml)
          xml_vars  = doc.css('variable_field_count').map(&:text)
          vartypes  = doc.css('variable_type').map(&:text)
          combos    = Hash[xml_vars.zip(vartypes)]

          rules     = { fields: {}, name: 'label' }
          xml_vars.each { |v| rules[:fields][v.to_sym] = { caption: "#{v} (#{combos[v]})" } }
          [rules, xml_vars]
        end
      end
    end
  end
end
