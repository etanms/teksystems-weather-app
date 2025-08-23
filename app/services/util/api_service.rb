# frozen_string_literal: true

module Util
  module ApiService
    def send_request(endpoint, args = {})
      data = send(endpoint, args)
      Util::Http::HttpService.send_request(**build_arguments(data))
    end
    
    private
    
    def build_arguments(args)
      {
        method:  args[:method] || Util::Http::HttpService::RequestMethods::GET,
        options: {
          body:             args[:body].present? ? JSON.generate(args[:body]) : nil,
          follow_redirects: true,
          headers:          JSON.parse((self::HEADERS || {}).to_json),
          query:            args[:query]
        },
        url:     self::BASE_URL + args[:path]
      }
    end
  end
end
