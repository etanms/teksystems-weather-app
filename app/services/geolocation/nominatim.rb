# frozen_string_literal: true

module Geolocation
  module Nominatim
    extend Util::ApiService
    
    BASE_URL = 'https://nominatim.openstreetmap.org'
    HEADERS  = { "User-Agent": "teksystems-weather-app/0.1 (etanms@gmail.com)" }
    
    # Module containing a list of constants, each representing a supported endpoint.
    module Endpoints
      GET_LAT_LON = 'get_lat_long'
    end
    
    private
    
    def self.get_lat_long(args)
      {
        query: {
          q:      "#{args[:zip]}, USA",
          format: :json
        },
        path:  '/search'
      }
    end
  end
end
