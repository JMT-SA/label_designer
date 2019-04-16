# frozen_string_literal: true

module Labels
  module Labels
    module Label
      # Module to be extended by view classes that need a list of label variables.
      # Read the label and unpack its variable XML as well as any saved values.
      module LabelVariableFields
        def vars_for_label(id, as_labels: false, &block)
          this_repo = LabelApp::LabelRepo.new
          obj       = this_repo.find_label(id)
          if obj.multi_label
            rules_for_multiple(this_repo, obj, as_labels, &block)
          else
            rules_for_single(obj, as_labels, &block)
          end
        end

        # Multi label: get variables from all sub-labels and assemble.
        def rules_for_multiple(repo, obj, as_labels) # rubocop:disable Metrics/AbcSize
          count = 0
          xml_vars = []
          vartypes = []
          repo.sub_label_ids(obj.id).each do |sub_label_id|
            sub_label = repo.find_label(sub_label_id)
            doc       = Nokogiri::XML(sub_label.variable_xml)
            sub_xml_vars = doc.css('variable_field_count').map do |var|
              "F#{var.text.sub(/f/i, '').to_i + count}"
            end
            count += sub_xml_vars.length
            xml_vars += sub_xml_vars
            vartypes += clean_up_compound_variable_names(doc.css('variable variable_type'))
          end
          combos = Hash[xml_vars.zip(vartypes)]

          rules = {}
          yield rules

          xml_vars.each do |v|
            rules[:fields][v.to_sym] = if as_labels
                                         { renderer: :label, with_value: combos[v] }
                                       else
                                         { caption: "#{v} (#{combos[v]})" }
                                       end
          end
          [obj, rules, xml_vars]
        end

        # Single label - get variables from just this label.
        def rules_for_single(obj, as_labels)
          doc       = Nokogiri::XML(obj.variable_xml)
          xml_vars  = doc.css('variable_field_count').map(&:text)
          vartypes  = clean_up_compound_variable_names(doc.css('variable variable_type'))
          combos    = Hash[xml_vars.zip(vartypes)]

          rules = {}
          yield rules

          xml_vars.each do |v|
            rules[:fields][v.to_sym] = if as_labels
                                         { renderer: :label, with_value: combos[v] }
                                       else
                                         { caption: "#{v} (#{combos[v]})" }
                                       end
          end
          [obj, rules, xml_vars]
        end

        def clean_up_compound_variable_names(vars)
          vars.map { |v| v.text.start_with?('CMP:') ? v.text.delete_prefix('CMP:').gsub(/[\$\{\}]/, '') : v.text }
        end
      end
    end
  end
end
