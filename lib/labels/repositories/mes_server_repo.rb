# frozen_string_literal: true

class MesServerRepo
  include Crossbeams::Responses

  def printer_list
    res = request_uri(printer_list_uri)
    return res unless res.success

    printer_list = YAML.safe_load(res.instance.body)
    success_response('Refreshed printers', printer_list['PrinterList'])
  end

  private

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
end
