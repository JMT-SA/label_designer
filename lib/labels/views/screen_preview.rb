module LabelView
  class ScreenPreview
    def self.call(id, form_values = nil, form_errors = nil)
      this_repo = LabelRepo.new
      obj       = this_repo.find_labels(id)
      doc       = Nokogiri::XML(obj.variable_xml)
      xml_vars  = doc.css('variable_field_count').map(&:text)
      vartypes  = doc.css('variable_type').map(&:text)
      combos    = Hash[xml_vars.zip(vartypes)]

      rules     = { fields: {}, name: 'label'.freeze }
      xml_vars.each { |v| rules[:fields][v.to_sym] = { caption: "#{v} (#{combos[v]})" } }
      var_obj = OpenStruct.new

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object var_obj
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action "/label_designer/#{id}/send_preview/screen"
          form.remote!
          xml_vars.each do |v|
            form.add_field v.to_sym
          end
        end
      end

      layout
    end
  end
end
