# frozen_string_literal: true

module LabelApp
  # Class to handle creating zip files of labels
  # - single labels
  # - multi-labels
  # - rotated labels
  class LabelFiles # rubocop:disable Metrics/ClassLength
    attr_reader :rotation

    def initialize(rotation = 0)
      @rotation = rotation
      raise Crossbeams::FrameworkError, "Label rotation can only be 0, 90 or -90. #{rotation} is not valid." unless [0, 90, -90].include?(rotation)
    end

    # Create a label zip file for publishing or previewing.
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

    # For export, dump the contents of all aspects of a label:
    # - image
    # - variable
    # - JSON
    # - label attributes (name, dimension and pixel resolution)
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

    # Read an uploaded label zip file and extract label attributes
    # for inserting into the db.
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

    private

    def make_combined_xml(label, fname) # rubocop:disable Metrics/AbcSize
      sub_label_ids = repo.sub_label_ids(label.id)
      raise Crossbeams::FrameworkError, "Multi-label \"#{label.label_name}\" has no sub-labels" if sub_label_ids.empty?

      first = repo.find_label(sub_label_ids.shift)
      doc = if rotation.zero?
              Nokogiri::XML(first.variable_xml)
            else
              Nokogiri::XML(rotate_xml(first.variable_xml, (first.px_per_mm || '8').to_i))
            end
      rename_image_in_xml(doc, fname, 1)
      sub_label_ids.each_with_index do |sub_label_id, index|
        sub_label = repo.find_label(sub_label_id)
        xml = if rotation.zero?
                sub_label.variable_xml
              else
                rotate_xml(sub_label.variable_xml, (sub_label.px_per_mm || '8').to_i)
              end
        new_label = Nokogiri::XML(xml).search('label')
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
      File.open('combo_vars.xml', 'w') { |f| f << combined_xml }
      Zip::OutputStream.write_buffer do |zio|
        repo.sub_label_ids(label.id).each_with_index do |sub_label_id, index|
          sub_label = repo.find_label(sub_label_id)
          sub_name = "#{fname}_#{index + 1}"
          zio.put_next_entry("#{sub_name}.png")
          if rotation.zero?
            zio.write sub_label.png_image
          else
            new_image = rotate_image(sub_label)
            zio.write new_image
          end
        end
        zio.put_next_entry("#{fname}.xml")
        zio.write combined_xml.chomp << "\n" # Ensure newline at end of file.
        zio.put_next_entry("#{fname}.properties")
        zio.write label_properties
      end
    end

    def zip_single_label(label, fname, label_properties) # rubocop:disable Metrics/AbcSize
      if rotation.zero?
        File.open('vars.xml', 'w') { |f| f << label.variable_xml }
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
      doc = Nokogiri::XML(xml)
      image_height = doc.at_xpath('//image_height').content.to_i
      image_width = doc.at_xpath('//image_width').content.to_i
      doc.xpath('//variable').each do |var| # rubocop:disable Metrics/BlockLength
        rot_angle = var.at_xpath('rotation_angle')
        startx = var.at_xpath('startx')
        starty = var.at_xpath('starty')
        baseline_x = var.at_xpath('baseline_x')
        baseline_y = var.at_xpath('baseline_y')
        width = var.at_xpath('width')
        height = var.at_xpath('height')
        size = var.at_xpath('fontsize_px').content.to_i

        cap_height = case var.at_xpath('fontfamily').content
                     when 'Arial'
                       (size * 0.72).round
                     when 'Times New Roman'
                       (size * 0.63).round
                     when 'Courier New'
                       (size * 0.66).round
                     else
                       size
                     end
        adjust = calculate_var_rotation(
          image_height: image_height - px_mm,
          image_width: image_width - px_mm,
          x1: startx.content.to_i,
          y1: starty.content.to_i,
          baseline_x: baseline_x.content.to_i,
          baseline_y: baseline_y.content.to_i,
          width: width.content.to_i,
          height: height.content.to_i,
          rotation: rot_angle.content.to_i,
          font_size_px: size,
          cap_height: cap_height
        )

        rot_angle.content = adjust[:rotation]
        startx.content = adjust[:startx]
        starty.content = adjust[:starty]
        width.content = adjust[:width]
        height.content = adjust[:height]
        baseline_x.content = adjust[:baseline_x]
        baseline_y.content = adjust[:baseline_y]
      end
      # puts doc.to_xml
      File.open('vars.xml', 'w') { |f| f << doc.to_xml }
      doc.to_xml.gsub(/>\s+</, '><')
    end

    def calculate_var_rotation(opts) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      # Note regarding positions and dimensions:
      # - Width and Height are always the width & height of the unrotated shape. i.e. they do not change when the shape is rotated.
      # - Baseline x,y are the points at which text should be printed and (relative to the shape's top-left before rotation) is x:0, y:0+font's CapHeight.
      # - StartX & startY are the top-left of the shape pre-rotation (which is then moved with the rotation).
      #
      # *-----W------.    .--V--*   .------------.    .--H--.    KEY
      # |            |    |  9  |   |            |    |  2  |    ---
      # > 0 deg      H    |  0  W   H 180 deg    <    W  7  |    >,V,<,^ : BaselineX, BaselineY and direction of text.
      # |            |    |     |   |            |    |  0  |    *       : StartX, StartY
      # .------------.    .--H--.   .-----W------*    *--^--.    W/H     : Width/Height
      #

      adj = { rotation: opts[:rotation] + rotation }
      adj[:rotation] = 0 if adj[:rotation] == 360
      adj[:rotation] = 270 if adj[:rotation] == -90

      adj[:width] = opts[:width]
      adj[:height] = opts[:height]

      # Rotate Right (90)
      if opts[:rotation].zero? && rotation == 90 # effectively 90
        adj[:startx] = opts[:image_height] - opts[:y1]
        adj[:starty] = opts[:x1]
        adj[:baseline_x] = opts[:image_height] - opts[:y1] - opts[:cap_height]
        adj[:baseline_y] = opts[:baseline_x]
      end
      if opts[:rotation] == 90 && rotation == 90 # effectively 180
        adj[:startx] = opts[:image_height] - opts[:y1]
        adj[:starty] = opts[:x1]
        adj[:baseline_x] = opts[:image_height] - opts[:y1]
        adj[:baseline_y] = opts[:x1] - opts[:cap_height]
      end
      if opts[:rotation] == 180 && rotation == 90 # effectively 270
        adj[:startx] = opts[:image_height] - opts[:y1]
        adj[:starty] = opts[:x1]
        adj[:baseline_x] = opts[:image_height] - opts[:y1] + opts[:cap_height]
        adj[:baseline_y] = opts[:x1]
      end
      if opts[:rotation] == 270 && rotation == 90 # effectively 0
        adj[:startx] = opts[:image_height] - opts[:y1]
        adj[:starty] = opts[:x1]
        adj[:baseline_x] = opts[:image_height] - opts[:y1]
        adj[:baseline_y] = opts[:x1] + opts[:cap_height]
      end

      # Rotate Left (-90)
      if opts[:rotation].zero? && rotation == -90 # effectively 270
        adj[:startx] = opts[:y1]
        adj[:starty] = opts[:image_width] - opts[:x1]
        adj[:baseline_x] = opts[:y1] + opts[:cap_height]
        adj[:baseline_y] = opts[:image_width] - opts[:x1]
      end
      if opts[:rotation] == 90 && rotation == -90 # effectively 0
        adj[:startx] = opts[:y1]
        adj[:starty] = opts[:image_width] - opts[:x1]
        adj[:baseline_x] = opts[:y1]
        adj[:baseline_y] = opts[:image_width] - opts[:x1] + opts[:cap_height]
      end
      if opts[:rotation] == 180 && rotation == -90 # effectively 90
        adj[:startx] = opts[:y1]
        adj[:starty] = opts[:image_width] - opts[:x1]
        adj[:baseline_x] = opts[:y1] - opts[:cap_height]
        adj[:baseline_y] = opts[:image_width] - opts[:x1]
      end
      if opts[:rotation] == 270 && rotation == -90 # effectively 180
        adj[:startx] = opts[:y1]
        adj[:starty] = opts[:image_width] - opts[:x1]
        adj[:baseline_x] = opts[:y1]
        adj[:baseline_y] = opts[:image_width] - opts[:x1] - opts[:cap_height]
      end
      adj
    end

    def combined_zip_filename
      "ld_publish_#{Date.today.strftime('%Y_%m_%d')}"
    end

    def repo
      @repo ||= LabelRepo.new
    end
  end
end
