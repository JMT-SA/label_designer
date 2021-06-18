# frozen_string_literal: true

# A class for logging HTTP call responses
module Crossbeams
  class HTTPTextCallLogger < HTTPBaseCallLogger
    attr_reader :log_path

    def initialize(keyword, log_body: true, log_path: nil)
      super(keyword, log_body: log_body)
      @log_path = log_path
    end

    def log_call(url, request, response, benchmk) # rubocop:disable Metrics/AbcSize
      attr = call_attributes(url, request, response, benchmk, nil)

      out = <<~STR
        -------------------
        #{keyword}
        #{attr[:request][:time]}
        -------------------
        ** REQUEST **
        method: #{attr[:request][:method]}
        url: #{attr[:request][:url]}
        request_body: #{attr[:request][:request_body]}
        #{attr[:request][:request_headers].join("\n")}

        ** RESPONSE **
        response_code: #{attr[:response][:response_code]}
        response_body: #{log_body ? attr[:response][:response_body] : 'not logged'}
        #{attr[:response][:response_headers].join("\n")}
        encoding: #{attr[:response][:encoding]}
        content_type: #{attr[:response][:content_type]}
        benchmark: #{attr[:response][:benchmark]}
      STR
      write(out)
    end

    def log_fail(url, request, exception) # rubocop:disable Metrics/AbcSize
      attr = call_attributes(url, request, nil, nil, exception)

      out = <<~STR
        -------------------
        #{keyword}
        #{attr[:request][:time]}
        -------------------
        ** REQUEST **
        method: #{attr[:request][:method]}
        url: #{attr[:request][:url]}
        request_body: #{attr[:request][:request_body]}
        #{attr[:request][:request_headers].join("\n")}

        ** FAILED **
        exception: #{attr[:fail][:exception]}
        message: #{attr[:fail][:message]}
      STR
      write(out)
    end

    private

    def write(out)
      if log_path.nil?
        puts out
      else
        File.open(log_path, 'a') { |f| f << out }
      end
    end
  end
end
