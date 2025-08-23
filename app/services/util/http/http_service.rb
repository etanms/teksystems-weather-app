# frozen_string_literal: true

module Util
  module Http
    # Service used to make HTTP requests using the HTTParty library.
    module HttpService
      require 'httparty'
      
      TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
      private_constant(:TIME_FORMAT)
      
      # List of HTTP request methods to be used as a parameter of the send_request method.
      module RequestMethods
        COPY    = 'copy'
        DELETE  = 'delete'
        GET     = 'get'
        HEAD    = 'head'
        MOVE    = 'move'
        OPTIONS = 'options'
        PATCH   = 'patch'
        POST    = 'post'
        PUT     = 'put'
      end
      
      # Makes a request using the given method to the given endpoint including the arguments passed within the options parameter.
      # @param [String] url The base URL of the request.
      # @param [String] method The HTTP request method to use. (i.e. GET, POST, DELETE, etc.)
      # @param [Hash] options A Hash containing data to be used for header and query arguments as well as request settings accepted by the HTTParty library.
      # @return [HTTParty::Response] The response from the given endpoint using the given options.
      
      def self.send_request(url:, method:, options: {})
        # Raise an exception if the method is not supported
        raise Util::Http::MethodNotSupportedError.new unless method_supported?(method)
        
        # Log and send the request
        log_request(url, method, options, now = DateTime.now)
        
        # Send request through HTTParty
        response = HTTParty.send(method, url, options)
        
        # Log and return the response
        log_response(response, now)
        response
      end
      
      class << self
        # Creates a standardized list of log statements based on the given request details.
        # @param [String] url The base URL of the request.
        # @param [String] method The HTTP request method to use. (i.e. GET, POST, DELETE, etc.)
        # @param [DateTime] time The time of the request.
        # @param [Hash] options A Hash containing data to be used for header and query arguments as well as request settings accepted by the HTTParty library.
        def log_request(url, method, options, time)
          # Convert body to JSON if necessary
          body = options[:body].class == String ? options[:body].as_hash : options[:body]
          
          # Create log record
          Rails.logger.info(
            """
        ____________________REQUEST____________________
        CURRENT TIME: #{time.strftime(TIME_FORMAT)}
        URL:          #{url}
        METHOD:       #{method.upcase}
        OPTIONS:      #{options.except(:body, :headers)}
        HEADERS:      #{options[:headers]}
        BODY:         #{(body&.to_h || body || '{}')}
        _______________________________________________
        """.cyan
          )
        end
        
        # Creates a standardized list of log statements based on the given response.
        # @param [HTTParty::Response] response The response to create log statements about.
        # @param [DateTime] time The time of the request.
        def log_response(response, time)
          now     = DateTime.now
          request = response.request
          
          # Try and parse the body as JSON, or use HTML body if parsing fails
          begin
            body = JSON.parse(response.body)
          rescue JSON::ParserError
            body = response.body
          end
          
          Rails.logger.info(
            """
        ____________________RESPONSE____________________
        CODE:         #{response.code}
        MESSAGE:      #{response.message}
        URL:          #{request.uri}
        LAST URL:     #{request.last_uri}
        METHOD:       #{request.http_method}
        CURRENT TIME: #{time.strftime(TIME_FORMAT)}
        TIME ELAPSED: #{(now.to_time - time.to_time).in_milliseconds} ms
        HEADERS:      #{response.headers.inspect}
        BODY:         #{body}
        ________________________________________________
        """.cyan
          )
        end
        
        # Validates that a given HTTP request method is supported by the HttpService class.
        # @param [String] method The method to validate.
        # @return [Boolean] true if the given method is supported by the HttpService class. false if otherwise.
        def method_supported?(method)
          RequestMethods.constants.map { |constant| RequestMethods.const_get(constant) }.include?(method)
        end
      end
    end
  end
end
