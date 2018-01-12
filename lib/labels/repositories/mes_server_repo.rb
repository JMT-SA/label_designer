# frozen_string_literal: true

class MesServerRepo
  include Crossbeams::Responses

  BOUNDARY = 'AaB03x'

  def printer_list
    res = request_uri(printer_list_uri)
    return res unless res.success

    printer_list = YAML.safe_load(res.instance.body)
    success_response('Refreshed printers', printer_list['PrinterList'])
  end

  def preview_label(screen_or_print, vars, fname, binary_data)
    res = post_binary(preview_uri, vars, screen_or_print, fname, binary_data)
    return res unless res.success
    success_response('ok', res.instance.body)
  end

  private

  def print_part_of_body(vars)
    post_body = []
    post_body << "--#{BOUNDARY}\r\n"
    post_body << "Content-Disposition: form-data; name=\"action\"\r\n"
    post_body << "\r\nprintlabel"
    post_body << "\r\n--#{BOUNDARY}--\r\n"
    post_body << "--#{BOUNDARY}\r\n"
    post_body << "Content-Disposition: form-data; name=\"printer\"\r\n"
    post_body << "\r\n#{vars[:printer]}"
    post_body << "\r\n--#{BOUNDARY}--\r\n"
    post_body
  end

  def shared_part_of_body(fname, binary_data)
    post_body = []
    post_body << "--#{BOUNDARY}\r\n"
    post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"#{fname}.zip\"\r\n"
    post_body << "Content-Type: application/x-zip-compressed\r\n"
    post_body << "\r\n"
    post_body << binary_data
    post_body << "\r\n--#{BOUNDARY}--\r\n"
    post_body
  end

  def post_binary(uri, vars, screen_or_print, fname, binary_data)
    post_body = screen_or_print == 'print' ? print_part_of_body(vars) : []
    post_body += shared_part_of_body(fname, binary_data)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = post_body.join
    request['Content-Type'] = "multipart/form-data, boundary=#{BOUNDARY}"

    response = http.request(request)
    format_response(response)
  rescue Timeout::Error
    failed_response('The call to the server timed out.')
  rescue Errno::ECONNREFUSED
    failed_response('The connection was refused. Perhaps the server is not running.')
  rescue StandardError => e
    failed_response("There was an error: #{e.message}")
  end

  def request_uri(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    format_response(response)
  rescue Timeout::Error
    failed_response('The call to the server timed out.')
  rescue Errno::ECONNREFUSED
    failed_response('The connection was refused. Perhaps the server is not running.')
  rescue StandardError => e
    failed_response("There was an error: #{e.message}")
  end

  def format_response(response)
    if response.code == '200'
      success_response(response.code, response)
    else
      msg = response.code.start_with?('5') ? 'The destination server encountered an error.' : 'The request was not successful.'
      failed_response("#{msg} The response code is #{response.code}")
    end
  end

  def printer_list_uri
    URI.parse("#{LABEL_SERVER_URI}?Type=GetPrinterList&ListType=yaml")
  end

  def preview_uri
    URI.parse("#{LABEL_SERVER_URI}LabelFileUpload")
  end
end
