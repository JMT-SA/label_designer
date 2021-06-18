# frozen_string_literal: true

# A class for logging HTTP call responses
module Crossbeams
  class HTTPBaseCallLogger
    attr_reader :keyword, :log_body

    def initialize(keyword, log_body: true)
      @log_body = log_body
      @keyword = keyword
    end

    def respond_to_missing?(method, include_private = false)
      %i[log_call log_fail].include?(method) || super
    end

    def method_missing(method, *args)
      return super unless %i[log_call log_fail].include?(method)

      raise Crossbeams::FrameworkError, "Crossbeams::HTTPBaseCallLogger##{method} is an abstract method to be implemented by inheriting classes."
    end

    def call_attributes(url, request, response, benchmk, err)
      {
        request: unpack_request(request, url),
        response: unpack_response(response, benchmk),
        fail: unpack_failure(err)
      }
    end

    def unpack_request(request, url)
      {
        time: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        method: request.method,
        url: url,
        request_body: request_body(request),
        request_headers: request.each_header.map { |k, v| "Header: #{k}: #{v}" }
      }
    end

    def unpack_response(response, benchmk)
      return {} if response.nil?

      {
        response_code: response.code,
        response_body: log_body ? response.body : nil,
        response_headers: response.each_header.map { |k, v| "Header: #{k}: #{v}" },
        encoding: response['Content-Encoding'],
        content_type: response['Content-Type'],
        benchmark: benchmk
      }
    end

    def unpack_failure(err)
      return {} if err.nil?

      {
        exception: err.class,
        message: err.message
      }
    end

    private

    def request_body(request)
      body_stream = request.body_stream
      if body_stream
        body_stream.to_s # read and rewind for RestClient::Payload::Base
        body_stream.rewind if body_stream.respond_to?(:rewind) # RestClient::Payload::Base has no method rewind
        body_stream.read
      elsif request.body.nil? || request.body.empty?
        nil # body
      else
        request.body
      end
    end
  end
end
