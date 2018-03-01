# frozen_string_literal: true

module LabelApp
  class LabelInteractor < BaseInteractor
    def repo
      @repo ||= LabelApp::LabelRepo.new
    end

    def label(cached = true)
      if cached
        @label ||= repo.find_label(@id)
      else
        @label = repo.find_label(@id)
      end
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
      @id = repo.create_label(res)
      success_response("Created label #{label.label_name}",
                       label)
    end

    def update_label(id, params)
      @id = id
      res = validate_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      repo.update_label(id, res)
      success_response("Updated label #{label.label_name}",
                       label(false))
    end

    def delete_label(id)
      @id = id
      name = label.label_name
      if label.multi_label
        repo.delete_label_with_sub_labels(id)
      else
        repo.delete_label(id)
      end
      success_response("Deleted label #{name}")
    end

    def link_multi_label(id, sub_label_ids)
      repo.link_multi_label(id, sub_label_ids)
      success_response('Linked sub-labels for a multi-label')
    end

    def validate_clone_label_params(params)
      LabelCloneSchema.call(params)
    end

    def can_preview?(id)
      @id = id
      if label.multi_label && repo.no_sub_labels(id).zero?
        failed_response('This multi-label does not have any linked sub-labels')
      else
        success_response('ok')
      end
    end

    def prepare_clone_label(id, params)
      res = validate_clone_label_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      @id = id
      attrs = {
        label_name: params[:label_name],
        container_type: label.container_type,
        commodity: label.commodity,
        market: label.market,
        language: label.language,
        category: label.category,
        sub_category: label.sub_category
      }
      success_response('Ok', attrs)
    end

    def background_images(id)
      res = can_preview?(id)
      return res unless res.success
      ids = if label.multi_label
              repo.sub_label_ids(id)
            else
              [id]
            end
      success_response('ok', ids)
    end

    def png_image(id)
      label = repo.find_label(id)
      label.png_image
    end

    def label_zip(id)
      label = repo.find_label(id)
      make_label_zip(label)
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
      label = repo.find_label(id)
      # Store the input variables:
      # repo.update_label(id, sample_data: "{#{vars.map { |k, v| %("#{k}":"#{v}") }.join(',')}}")
      repo.update_label(id, sample_data: repo.hash_to_jsonb_str(vars))

      fname, binary_data = make_label_zip(label, vars)
      File.open('zz.zip', 'w') { |f| f.puts binary_data }

      mes_repo = MesServerRepo.new
      res = mes_repo.preview_label(screen_or_print, vars, fname, binary_data)
      if res.success
        success_response("Sent preview to #{screen_or_print}.", OpenStruct.new(fname: fname, body: res.instance))
      else
        failed_response(res.message)
      end
    end

    # def do_preview_full(id, screen_or_print)
    #   response['Content-Type'] = 'application/json'
    #   begin
    #     vars  = params[:label]
    #     repo  = LabelRepo.new
    #     label = repo.find_label(id)
    #
    #     fname, binary_data = make_label_zip(label, vars)
    #     File.open('zz.zip', 'w') { |f| f.puts binary_data }
    #     uri = URI.parse(LABEL_SERVER_URI + 'LabelFileUpload')
    #
    #     post_body = []
    #     if screen_or_print == 'print'
    #       post_body << "--#{BOUNDARY}\r\n"
    #       post_body << "Content-Disposition: form-data; name=\"action\"\r\n"
    #       post_body << "\r\nprintlabel"
    #       post_body << "\r\n--#{BOUNDARY}--\r\n"
    #       post_body << "--#{BOUNDARY}\r\n"
    #       post_body << "Content-Disposition: form-data; name=\"printer\"\r\n"
    #       post_body << "\r\n#{vars[:printer]}"
    #       post_body << "\r\n--#{BOUNDARY}--\r\n"
    #     end
    #     post_body << "--#{BOUNDARY}\r\n"
    #     post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"#{fname}.zip\"\r\n"
    #     post_body << "Content-Type: application/x-zip-compressed\r\n"
    #     post_body << "\r\n"
    #     post_body << binary_data
    #     post_body << "\r\n--#{BOUNDARY}--\r\n"
    #
    #     http = Net::HTTP.new(uri.host, uri.port)
    #     request = Net::HTTP::Post.new(uri.request_uri)
    #     request.body = post_body.join
    #     request['Content-Type'] = "multipart/form-data, boundary=#{BOUNDARY}"
    #
    #     response = http.request(request)
    #     if response.code == '200'
    #       filepath = Tempfile.open([fname, '.png'], 'public/tempfiles') do |f|
    #         f.write(response.body)
    #         f.path
    #       end
    #       { replaceDialog: { content: "<img src='/#{File.join('tempfiles', File.basename(filepath))}'>" } }.to_json
    #     elsif response.code.start_with?('5')
    #       { flash: { error: "The destination server encountered an error. The response code is #{response.code}, response body: #{response.body}" } }.to_json
    #     else
    #       { flash: { error: "The request was not successful. The response code is #{response.code}" } }.to_json
    #     end
    #   rescue Timeout::Error
    #     { flash: { error: 'The call to the server timed out.' } }.to_json
    #   rescue Errno::ECONNREFUSED
    #     { flash: { error: 'The connection was refused. Perhaps the server is not running.' } }.to_json
    #   rescue StandardError => e
    #     { flash: { error: "There was an error: #{e.class.name} - #{e.message}" } }.to_json
    #   end
    # end
  end
end
