# frozen_string_literal: true

# A class for making HTTP calls
module Crossbeams
  class HTTPCalls # rubocop:disable Metrics/ClassLength
    include Crossbeams::Responses
    attr_reader :use_ssl, :call_logger

    def initialize(use_ssl: false, responder: nil, open_timeout: 5, read_timeout: 10, call_logger: nil)
      @use_ssl = use_ssl
      @responder = responder
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @call_logger = call_logger
    end

    # See if a host is reachable via ping.
    #
    # @param url_or_host [string] the url, hostname or ip address to check.
    # @return [boolean] True if the ping succeeded.
    def can_ping?(url_or_host)
      uri = URI.parse(url_or_host)
      pe = Net::Ping::External.new(uri.host || uri.path)
      pe.timeout = 1
      pe.ping?
    end

    def json_post(url, params, headers = {}) # rubocop:disable Metrics/AbcSize
      uri, http = setup_http(url)
      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
      headers.each do |k, v|
        request.add_field(k.to_s, v.to_s)
      end
      request.body = params.to_json

      log_request(request)

      bm = Benchmark.realtime do
        @response = http.request(request)
      end
      call_logger&.log_call(url, request, @response, bm)
      format_response(@response, uri)
    rescue Timeout::Error => e
      call_logger&.log_fail(url, request, e)
      failed_response('The call to the server timed out.', timeout: true)
    rescue Errno::ECONNREFUSED => e
      call_logger&.log_fail(url, request, e)
      failed_response('The connection was refused. Perhaps the server is not running.', refused: true)
    rescue StandardError => e
      call_logger&.log_fail(url, request, e)
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: "URI is #{uri}")
      failed_response("There was an error: #{e.message}")
    end

    def json_put(url, params, headers = {}) # rubocop:disable Metrics/AbcSize
      uri, http = setup_http(url)
      request = Net::HTTP::Put.new(uri.request_uri, 'Content-Type' => 'application/json')
      headers.each do |k, v|
        request.add_field(k.to_s, v.to_s)
      end
      request.body = params.to_json

      log_request(request)

      bm = Benchmark.realtime do
        @response = http.request(request)
      end
      call_logger&.log_call(url, request, @response, bm)
      format_response(@response, uri)
    rescue Timeout::Error => e
      call_logger&.log_fail(url, request, e)
      failed_response('The call to the server timed out.', timeout: true)
    rescue Errno::ECONNREFUSED => e
      call_logger&.log_fail(url, request, e)
      failed_response('The connection was refused. Perhaps the server is not running.', refused: true)
    rescue StandardError => e
      call_logger&.log_fail(url, request, e)
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: "URI is #{uri}")
      failed_response("There was an error: #{e.message}")
    end

    def json_delete(url, params, headers = {}) # rubocop:disable Metrics/AbcSize
      uri, http = setup_http(url)
      request = Net::HTTP::Delete.new(uri.request_uri, 'Content-Type' => 'application/json')
      headers.each do |k, v|
        request.add_field(k.to_s, v.to_s)
      end
      request.body = params.to_json

      log_request(request)

      bm = Benchmark.realtime do
        @response = http.request(request)
      end
      call_logger&.log_call(url, request, @response, bm)
      format_response(@response, uri)
    rescue Timeout::Error => e
      call_logger&.log_fail(url, request, e)
      failed_response('The call to the server timed out.', timeout: true)
    rescue Errno::ECONNREFUSED => e
      call_logger&.log_fail(url, request, e)
      failed_response('The connection was refused. Perhaps the server is not running.', refused: true)
    rescue StandardError => e
      call_logger&.log_fail(url, request, e)
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: "URI is #{uri}")
      failed_response("There was an error: #{e.message}")
    end

    def xml_post(url, xml) # rubocop:disable Metrics/AbcSize
      uri, http = setup_http(url)
      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/xml')
      request.body = xml

      log_request(request)

      bm = Benchmark.realtime do
        @response = http.request(request)
      end
      call_logger&.log_call(url, request, @response, bm)
      format_response(@response, uri)
    rescue Timeout::Error => e
      call_logger&.log_fail(url, request, e)
      failed_response('The call to the server timed out.', timeout: true)
    rescue Errno::ECONNREFUSED => e
      call_logger&.log_fail(url, request, e)
      failed_response('The connection was refused. Perhaps the server is not running.', refused: true)
    rescue StandardError => e
      call_logger&.log_fail(url, request, e)
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: "URI is #{uri}")
      failed_response("There was an error: #{e.message}")
    end

    def request_get(url, headers = {}) # rubocop:disable Metrics/AbcSize
      uri, http = setup_http(url)
      request = Net::HTTP::Get.new(uri.request_uri)
      headers.each do |k, v|
        request.add_field(k.to_s, v.to_s)
      end

      bm = Benchmark.realtime do
        @response = http.request(request)
      end
      call_logger&.log_call(url, request, @response, bm)
      log_request(request)

      format_response(@response, uri)
    rescue Timeout::Error => e
      call_logger&.log_fail(url, request, e)
      failed_response('The call to the server timed out.', timeout: true)
    rescue Errno::ECONNREFUSED => e
      call_logger&.log_fail(url, request, e)
      failed_response('The connection was refused. Perhaps the server is not running.', refused: true)
    rescue StandardError => e
      call_logger&.log_fail(url, request, e)
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: "URI is #{uri}")
      failed_response("There was an error: #{e.message}")
    end

    def request_post(url, fields, headers = {}) # rubocop:disable Metrics/AbcSize
      uri, http = setup_http(url)
      request = Net::HTTP::Post.new(uri.request_uri)
      headers.each do |k, v|
        request.add_field(k.to_s, v.to_s)
      end

      request.set_form_data(fields)
      log_request(request)
      bm = Benchmark.realtime do
        @response = http.request(request)
      end
      call_logger&.log_call(url, request, @response, bm)

      format_response(@response, uri)
    rescue Timeout::Error => e
      call_logger&.log_fail(url, request, e)
      failed_response('The call to the server timed out.', timeout: true)
    rescue Errno::ECONNREFUSED => e
      call_logger&.log_fail(url, request, e)
      failed_response('The connection was refused. Perhaps the server is not running.', refused: true)
    rescue StandardError => e
      call_logger&.log_fail(url, request, e)
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: "URI is #{uri}")
      failed_response("There was an error: #{e.message}")
    end

    private

    def setup_http(url)
      @use_ssl = true if url.include?('https:')

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      http.use_ssl = @use_ssl if @use_ssl
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      [uri, http]
    end

    def format_response(response, context)
      return @responder.format_response(response, context) if @responder

      case response.code
      when '200'
        success_response(response.code, response)
      when '429'
        failed_response("The destination server has received too many requests at this time. (quota exceeded) The response code is #{response.code}", response.code)
      else
        msg = response.code.start_with?('5') ? 'The destination server encountered an error.' : 'The request was not successful.'
        send_error_email(response, context)
        failed_response("#{msg} The response code is #{response.code}", response.code)
      end
    end

    def send_error_email(response, context)
      body = []
      body << "The HTTP call was:\n#{context}" unless context.nil?
      body << if response.body.encoding == Encoding::ASCII_8BIT
                'An image was probably returned'
              else
                "The response from the call was:\n------------------------------\n#{response.body}"
              end
      ErrorMailer.send_error_email(subject: "An HTTP call responded with error code #{response.code}",
                                   message: body.join("\n\n"))
    end

    def log_request(request)
      return if AppConst.test?

      if request.method == 'GET'
        puts ">>> HTTP call: #{request.method} >> #{request.path}"
      else
        body = ENV['LOGFULLMESSERVERCALLS'] ? request.body : request.body[0, 300]
        puts ">>> HTTP call: #{request.method} >> #{request.path} > #{body}"
      end
    end
  end
end
