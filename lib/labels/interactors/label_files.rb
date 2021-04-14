# frozen_string_literal: true

module LabelApp
  class LabelFiles # rubocop:disable Metrics/ClassLength
    attr_reader :rotation

    def initialize(rotation = 0)
      @rotation = rotation
      raise Crossbeams::FrameworkError, "Label rotation can only be 0, 90 or -90. #{rotation} is not valid." unless [0, 90, -90].include?(rotation)
    end

    def make_label_zip(label, vars = nil)
      property_vars = vars ? vars.map { |k, v| "\n#{k}=#{v}" }.join : "\nF1=Variable Test Value"
      fname = label.label_name.strip.gsub(%r{[/:*?"\\<>|\r\n]}i, '-')
      label_properties = %(Client: Name="NoSoft"\nF0=nsld:#{fname}#{property_vars}) # For testing only
      stringio = if label.multi_label
                   zip_multi_label(label, fname, label_properties)
                 else
                   zip_single_label(label, fname, label_properties)
                 end
      [fname, stringio.string]
    end

    def make_export_zip(label) # rubocop:disable Metrics/AbcSize
      attrs = { 'label_name': label.label_name,
                'label_dimension': label.label_dimension,
                'px_per_mm': label.px_per_mm }
      stringio = Zip::OutputStream.write_buffer do |zio|
        zio.put_next_entry('png_image')
        zio.write label.png_image
        zio.put_next_entry('variable_xml')
        zio.write label.variable_xml
        zio.put_next_entry('label_json')
        zio.write label.label_json.to_s
        zio.put_next_entry('attributes')
        zio.write attrs.to_json
      end
      [label.label_name, stringio.string]
    end

    def import_file(tempfile, attrs)
      Zip::InputStream.open(tempfile) do |io|
        while (entry = io.get_next_entry)
          case entry.name
          when 'attributes'
            temps = JSON.parse(io.read)
            attrs[:label_dimension] = temps['label_dimension']
            attrs[:px_per_mm] = temps['px_per_mm']
          when 'png_image'
            attrs[:png_image] = Sequel.blob(io.read)
          else
            attrs[entry.name.to_sym] = io.read
          end
        end
      end
      attrs
    end

    def make_combined_xml(label, fname) # rubocop:disable Metrics/AbcSize
      sub_label_ids = repo.sub_label_ids(label.id)
      raise Crossbeams::FrameworkError, "Multi-label \"#{label.label_name}\" has no sub-labels" if sub_label_ids.empty?

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

    def zip_multi_label(label, fname, label_properties) # rubocop:disable Metrics/AbcSize
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

    def zip_single_label(label, fname, label_properties) # rubocop:disable Metrics/AbcSize
      if rotation.zero?
        Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry("#{fname}_1.png")
          zio.write label.png_image
          zio.put_next_entry("#{fname}.xml")
          zio.write label.variable_xml.chomp << "\n" # Ensure newline at end of file.
          zio.put_next_entry("#{fname}.properties")
          zio.write label_properties
        end
      else
        new_image = rotate_image(label)
        new_xml = rotate_xml(label.variable_xml, (label.px_per_mm || '8').to_i)
        Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry("#{fname}_1.png")
          zio.write new_image
          zio.put_next_entry("#{fname}.xml")
          zio.write new_xml.chomp << "\n" # Ensure newline at end of file.
          zio.put_next_entry("#{fname}.properties")
          zio.write label_properties
        end
      end
    end

    def rotate_image(label)
      outfile = Tempfile.new(['lbl', '.png'])

      Tempfile.open(['lbl', '.png']) do |f|
        f.write(label.png_image)
        f.flush
        res = system("convert #{f.path} -rotate #{rotation} #{outfile.path}")
        raise Crossbeams::InfoError, 'Unable to rotate image' unless res
      end

      File.read(outfile.path)
    ensure
      outfile.close
    end

    def rotate_xml(xml, px_mm) # rubocop:disable Metrics/AbcSize
      # TODO: Make this more intelligent - rotate 90 / -90 and also adjust already-rotated vars
      raise Crossbeams::FrameworkError, "Rotation of #{rotation} degrees has not been implemented yet." unless rotation == 90

      doc = Nokogiri::XML(xml)
      image_height = doc.at_xpath('//image_height').content.to_i
      image_width = doc.at_xpath('//image_width').content.to_i
      doc.xpath('//variable').each do |var|
        rot_angle = var.at_xpath('rotation_angle')
        startx = var.at_xpath('startx')
        starty = var.at_xpath('starty')
        width = var.at_xpath('width')
        height = var.at_xpath('height')
        size = var.at_xpath('fontsize_px').content.to_i

        adjust = calculate_var_rotation(
          image_height: image_height,
          image_width: image_width,
          x1: startx.content.to_i,
          y1: starty.content.to_i,
          width: width.content.to_i,
          height: height.content.to_i,
          rotation: rot_angle.content.to_i,
          px_mm: px_mm,
          font_size_px: size.to_i
        )

        rot_angle.content = adjust[:rotation]
        startx.content = adjust[:startx]
        starty.content = adjust[:starty]
        width.content = adjust[:width]
        height.content = adjust[:height]
      end
      # puts doc.to_xml
      doc.to_xml.gsub(/>\s+</, '><')
    end

    def calculate_var_rotation(opts) # rubocop:disable Metrics/AbcSize
      # TODO: does printing work with -90? or should it be 270?
      adj = { rotation: opts[:rotation] + rotation }
      # adj[:rotation] = 0 if adj[:rotation] == 360 # change -90 to 270?
      # Following hard-coded for rotate 0 to 90
      adj[:width] = opts[:height]
      adj[:height] = opts[:width]
      adj[:startx] = opts[:image_height] - adj[:width] - opts[:y1] + opts[:px_mm] + opts[:font_size_px]
      adj[:starty] = opts[:x1]
      adj
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

    def repo
      @repo ||= LabelRepo.new
    end
  end
end
