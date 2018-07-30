# frozen_string_literal: true

module LabelApp
  class LabelFiles
    def repo
      @repo ||= LabelRepo.new
    end

    def make_label_zip(label, vars = nil)
      property_vars = vars ? vars.map { |k, v| "\n#{k}=#{v}" }.join : "\nF1=Variable Test Value"
      fname = label.label_name.strip.gsub(%r{[/:*?"\\<>\|\r\n]}i, '-')
      label_properties = %(Client: Name="NoSoft"\nF0=nsld:#{fname}#{property_vars}) # For testing only
      stringio = if label.multi_label
                   zip_multi_label(label, fname, label_properties)
                 else
                   zip_single_label(label, fname, label_properties)
                 end
      [fname, stringio.string]
    end

    def make_combined_xml(label, fname)
      sub_label_ids = repo.sub_label_ids(label.id)
      first = repo.find_label(sub_label_ids.shift)
      doc = Nokogiri::XML(first.variable_xml)
      rename_image_in_xml(doc, fname, 1)
      sub_label_ids.each_with_index do |sub_label_id, index|
        sub_label = repo.find_label(sub_label_id)
        new_label = Nokogiri::XML(sub_label.variable_xml).search('label')
        rename_image_in_xml(new_label, fname, index + 2)
        doc.at('labels').add_child(new_label)
      end
      doc.to_xml
    end

    def rename_image_in_xml(doc, fname, index)
      img = doc.search('image_filename')
      img[0].replace("<image_filename>#{fname}_#{index}.png</image_filename>")
    end

    def zip_multi_label(label, fname, label_properties)
      combined_xml = make_combined_xml(label, fname)
      Zip::OutputStream.write_buffer do |zio|
        repo.sub_label_ids(label.id).each_with_index do |sub_label_id, index|
          sub_label = repo.find_label(sub_label_id)
          sub_name = "#{fname}_#{index + 1}"
          zio.put_next_entry("#{sub_name}.png")
          zio.write sub_label.png_image
        end
        zio.put_next_entry("#{fname}.xml")
        zio.write combined_xml.chomp << "\n" # Ensure newline at end of file.
        zio.put_next_entry("#{fname}.properties")
        zio.write label_properties
      end
    end

    def zip_single_label(label, fname, label_properties)
      Zip::OutputStream.write_buffer do |zio|
        zio.put_next_entry("#{fname}_1.png")
        zio.write label.png_image
        zio.put_next_entry("#{fname}.xml")
        zio.write label.variable_xml.chomp << "\n" # Ensure newline at end of file.
        zio.put_next_entry("#{fname}.properties")
        zio.write label_properties
      end
    end

    # Create a zip file of zipped labels for publishing.
    def make_combined_zip(label_ids)
      stringio = Zip::OutputStream.write_buffer do |zio|
        repo.all(:labels, LabelApp::Label, id: label_ids).each do |sub_label|
          fname, binary_data = make_label_zip(sub_label)
          zio.put_next_entry("#{fname}.zip")
          zio.write binary_data
        end
      end
      [combined_zip_filename, stringio.string]
    end

    def combined_zip_filename
      "ld_publish_#{Date.today.strftime('%Y_%m_%d')}"
    end
  end
end
