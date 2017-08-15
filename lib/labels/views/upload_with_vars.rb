# require './lib/labels/repositories/label_repo.rb'
module LabelView
  class UploadWithVars
    def self.call(id, form_values = nil, form_errors = nil)
      this_repo = LabelRepo.new
      obj       = this_repo.find(id)
      doc       = Nokogiri::XML(obj.variable_xml)
      xml_vars  = doc.css('variable_count').map { |v| v.text }
      rules = { fields: {}, name: 'label'.freeze }
      xml_vars.each { |v| rules[v.to_sym] = {} }
      var_obj = OpenStruct.new

      layout = Crossbeams::Layout::Page.build(rules) do |page|
        page.form_object var_obj
        page.form_values form_values
        page.form_errors form_errors
        page.form do |form|
          form.action "/label_designer/#{id}/send_var_upload"
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

