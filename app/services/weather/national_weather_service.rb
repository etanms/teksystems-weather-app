# frozen_string_literal: true

module Weather
  module NationalWeatherService
    extend Util::ApiService
    
    BASE_URL = 'https://api.weather.gov'
    HEADERS  = { "User-Agent": "teksystems-weather-app/0.1 (etanms@gmail.com)" }
    
    # Module containing a list of constants, each representing a supported endpoint.
    module Endpoints
      GET_FORECAST      = 'get_forecast'
      GET_LOCATION_DATA = 'get_location_data'
    end
    
    class << self
      def get_forecast(args)
        { path: "/gridpoints/#{args[:grid_id]}/#{args[:x]},#{args[:y]}/forecast" }
      end
      
      def get_location_data(args)
        { path: "/points/#{args[:lat]},#{args[:lon]}" }
      end
    end
  end
end
