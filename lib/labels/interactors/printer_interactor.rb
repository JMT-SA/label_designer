# frozen_string_literal: true

class PrinterInteractor < BaseInteractor
  def repo
    @repo ||= PrinterRepo.new
  end

  def refresh_printers
    # get yml list & populate table
    uri = URI.parse("#{LABEL_SERVER_URI}?Type=GetPrinterList&ListType=yaml")
    p uri

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    printer_list = YAML.safe_load(response.body)

    repo.delete_and_add_printers(printer_list['PrinterList'])

    if response.code == '200'
      success_response('Refreshed printers')
    elsif response.code.start_with?('5')
      failed_response("The destination server encountered an error. The response code is #{response.code}")
    else
      failed_response("The request was not successful. The response code is #{response.code}")
    end
  rescue Timeout::Error
    failed_response('The call to the server timed out.')
  rescue Errno::ECONNREFUSED
    failed_response('The connection was refused. Perhaps the server is not running.')
  rescue StandardError => e
    failed_response("There was an error: #{e.message}")
  end

  def printer(cached = true)
    if cached
      @printer ||= repo.find_printer(@id)
    else
      @printer = repo.find_printer(@id)
    end
  end

  def validate_printer_params(params)
    PrinterSchema.call(params)
  end

  def create_printer(params)
    res = validate_printer_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    @id = repo.create_printer(res)
    success_response("Created printer #{printer.name}",
                     printer)
  end

  def update_printer(id, params)
    @id = id
    res = validate_printer_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    repo.update_printer(id, res)
    success_response("Updated printer #{printer.name}",
                     printer(false))
  end

  def delete_printer(id)
    @id = id
    name = printer.name
    repo.delete_printer(id)
    success_response("Deleted printer #{name}")
  end
end
