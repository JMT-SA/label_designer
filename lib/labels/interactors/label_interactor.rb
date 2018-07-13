# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module LabelApp
  class LabelInteractor < BaseInteractor
    def repo
      @repo ||= LabelRepo.new
    end

    def label(id)
      repo.find_label(id)
    end

    def validate_label_params(params)
      LabelSchema.call(params)
    end

    def pre_create_label(params)
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      attrs = {
        container_type: params[:container_type],
        commodity: params[:commodity],
        market: params[:market],
        language: params[:language],
        category: params[:category],
        sub_category: params[:sub_category]
      }
      success_response('Ok', attrs)
    end

    def create_label(params)
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      id = nil
      DB.transaction do
        id = repo.create_label(res)
        log_transaction
      end
      instance = label(id)
      success_response("Created label #{instance.label_name}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { label_name: ['This label already exists'] }))
    end

    def update_label(id, params)
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      DB.transaction do
        repo.update_label(id, res)
        log_transaction
      end
      instance = label(id)
      success_response("Updated label #{instance.label_name}",
                       instance)
    end

    def delete_label(id)
      instance = label(id)
      DB.transaction do
        if instance.multi_label
          repo.delete_label_with_sub_labels(id)
        else
          repo.delete_label(id)
        end
        log_transaction
      end
      success_response("Deleted label #{instance.label_name}")
    end

    def link_multi_label(id, sub_label_ids)
      repo.link_multi_label(id, sub_label_ids)
      success_response('Linked sub-labels for a multi-label')
    end

    def validate_clone_label_params(params)
      LabelCloneSchema.call(params)
    end

    def can_preview?(id)
      if label(id).multi_label && repo.no_sub_labels(id).zero?
        failed_response('This multi-label does not have any linked sub-labels')
      else
        success_response('ok')
      end
    end

    def prepare_clone_label(id, params)
      res = validate_clone_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      instance = label(id)
      attrs = {
        label_name: params[:label_name],
        container_type: instance.container_type,
        commodity: instance.commodity,
        market: instance.market,
        language: instance.language,
        category: instance.category,
        sub_category: instance.sub_category
      }
      success_response('Ok', attrs)
    end

    def background_images(id)
      res = can_preview?(id)
      return res unless res.success
      ids = if label(id).multi_label
              repo.sub_label_ids(id)
            else
              [id]
            end
      success_response('ok', ids)
    end

    def png_image(id)
      instance = label(id)
      instance.png_image
    end

    def label_zip(id)
      instance = label(id)
      make_label_zip(instance)
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

    def do_preview(id, screen_or_print, vars)
      instance = label(id)
      # Store the input variables:
      # repo.update_label(id, sample_data: "{#{vars.map { |k, v| %("#{k}":"#{v}") }.join(',')}}")
      repo.update_label(id, sample_data: repo.hash_to_jsonb_str(vars))

      fname, binary_data = make_label_zip(instance, vars)
      File.open('zz.zip', 'w') { |f| f.puts binary_data }

      mes_repo = MesServerRepo.new
      res = mes_repo.preview_label(screen_or_print, vars, fname, binary_data)
      if res.success
        success_response("Sent preview to #{screen_or_print}.", OpenStruct.new(fname: fname, body: res.instance))
      else
        failed_response(res.message)
      end
    end

    def publish_labels(vars)
      # {:printer_type=>"Datamax", :targets=>["192.168.50.201", "192.168.50.200"], :label_ids=>[5, 6, 23]}
      # instance = label(id)
      # Store the input variables:
      # repo.update_label(id, sample_data: repo.hash_to_jsonb_str(vars))
      # TODO: store history of publishing...

      fname, binary_data = make_combined_zip(vars[:label_ids])
      # File.open('zz.zip', 'w') { |f| f.puts binary_data }

      mes_repo = MesServerRepo.new
      res = mes_repo.send_publish_package(vars[:printer_type], vars[:targets], fname, binary_data)
      if res.success
        success_response('Published labels.', OpenStruct.new(fname: fname, body: res.instance))
      else
        failed_response(res.message)
      end
    end

    def publishing_status(vars)
      mes_repo = MesServerRepo.new
      res = mes_repo.send_publish_status(vars[:printer_type], combined_zip_filename)
      if res.success
        # TODO: use step wrapper to do formatting
        success_response('Published labels.', OpenStruct.new(done: all_published?(vars, res.instance), body: publishing_table(vars, res.instance))) # decide on done...
      elsif res.instance == '404' # Nothing sent yet...
        success_response('Published labels.', OpenStruct.new(done: false, body: publishing_table(vars, [])))
      else
        failed_response(res.message, res.instance) # instance is response code
      end
    end

    def all_published?(vars, response_body)
      expected = vars[:targets].length * vars[:label_ids].length
      response_body.length == expected && response_body.all? { |item| !item['Status'].nil? }
    end

    def publishing_table(vars, response_body)
      lkp = publishing_table_lookup(response_body)
      cols = vars[:targets].sort.unshift('Label')
      rows = publishing_table_rows(lkp)
      # Placeholders for not-sent labels...
      publishing_table_add_missing_rows(rows, vars, lkp)
      Crossbeams::Layout::Table.new({}, rows, cols, cell_classes: publishing_table_classes(vars[:targets])).render
    end

    def publishing_table_add_missing_rows(rows, vars, lkp)
      # ((vars[:label_ids].length + 1) - lkp.keys.length).times { rows << { 'Label' => '...', '192.168.50.200' => '500 Dummy err' } }
      (vars[:label_ids].length - lkp.keys.length).times { rows << { 'Label' => '...', '192.168.50.200' => '500 Dummy err' } }
    end

    def publishing_table_classes(targets)
      rules = {}
      targets.each do |target|
        rules[target] = ->(status) { status.to_s.include?('200') ? 'green' : 'red' }
      end
      rules
    end

    def publishing_table_rows(lkp)
      lkp.keys.map do |key|
        { 'Label' => key }.merge(lkp[key])
      end
    end

    def publishing_table_lookup(response_body)
      lkp = {}
      response_body.each do |item|
        key = item['File'].sub('.zip', '')
        lkp[key] ||= {}
        lkp[key][item['To']] = item['Status']
        # would be nice to send a class to the cell td
        # if in column def, have lambda rule to call
      end
      lkp
    end

    #  - File: RUS_SU8206a.zip
    #    Status:  200 OK
    #    To: 192.168.50.202
    #    PrinterType: Datamax
    #    Date:  07-11-2018
    #    Time:  08:27:06
    #  - File: RUS_SU8206a.zip
    #    Status:  200 OK
    #    To: 192.168.50.201
    #    PrinterType: Datamax
    #    Date:  07-11-2018
    #    Time:  08:27:06
    #  - File: RUS_SU8206.zip
    #    Status:  200 OK
    #    To: 192.168.50.202
    #    PrinterType: Datamax
    #    Date:  07-11-2018
    #    Time:  08:27:06
    #  - File: RUS_SU8206.zip
    #    Status:  200 OK
    #    To: 192.168.50.201
    #    PrinterType: Datamax
    #    Date:  07-11-2018
    #    Time:  08:27:06

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

    def dummy
      success_response('Published labels.', OpenStruct.new(fname: 'filename', body: 'returned'))
    end
  end
end
# rubocop:enable Metrics/ClassLength
