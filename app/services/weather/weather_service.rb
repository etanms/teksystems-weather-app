# frozen_string_literal: true

module Weather
  module WeatherService
    def self.get_forecast(args)
      # Retrieve data about the location specified by the lat/lon within args
      response   = NationalWeatherService.send_request(NationalWeatherService::Endpoints::GET_LOCATION_DATA, args)
      properties = response.body.as_hash['properties']
      
      # Use the retrieved data to retrieve the forecast for this location
      location_args = { grid_id: properties['gridId'], x: properties['gridX'], y: properties['gridY'] }
      response      = NationalWeatherService.send_request(
                        NationalWeatherService::Endpoints::GET_HOURLY_FORECAST,
                        location_args
                      )
      
      # Return forecast data
      response.body.as_hash
    end
  end
end
