# frozen_string_literal: true

class WeatherController < ApplicationController
  CACHE_DURATION = 30.minutes
  
  def forecast
    # Extract zip code
    zip = address_params[:zip]
    
    # Attempt to retrieve the forecast from the cache, or retrieve it from API if not recently cached
    @forecast = Rails.cache.fetch({ type: :weather_forecast, zip: zip }) || get_forecast(zip)
    
    # Sample Forecast:
    #
    # [{"number" => 1,
    #   "name" => "Today",
    #   "startTime" => "2025-08-23T06:00:00-07:00",
    #   "endTime" => "2025-08-23T18:00:00-07:00",
    #   "isDaytime" => true,
    #   "temperature" => 92,
    #   "temperatureUnit" => "F",
    #   "temperatureTrend" => "",
    #   "probabilityOfPrecipitation" => {"unitCode" => "wmoUnit:percent", "value" => 7},
    #   "windSpeed" => "2 to 9 mph",
    #   "windDirection" => "WNW",
    #   "icon" => "https://api.weather.gov/icons/land/day/sct?size=medium",
    #   "shortForecast" => "Mostly Sunny",
    #   "detailedForecast" => "Mostly sunny. High near 92, with temperatures falling to around 88 in the afternoon. West northwest wind 2 to 9 mph."},
    #  {"number" => 2,
    #   "name" => "Tonight",
    #   "startTime" => "2025-08-23T18:00:00-07:00",
    #   "endTime" => "2025-08-24T06:00:00-07:00",
    #   "isDaytime" => false,
    #   "temperature" => 60,
    #   "temperatureUnit" => "F",
    #   "temperatureTrend" => "",
    #   "probabilityOfPrecipitation" => {"unitCode" => "wmoUnit:percent", "value" => 10},
    #   "windSpeed" => "3 to 8 mph",
    #   "windDirection" => "WNW",
    #   "icon" => "https://api.weather.gov/icons/land/night/few?size=medium",
    #   "shortForecast" => "Mostly Clear",
    #   "detailedForecast" => "Mostly clear, with a low around 60. West northwest wind 3 to 8 mph."},
    #  ...
    # ]
    
    # Render response based on the requested response format
    respond_to do |format|
      format.html # Renders app/views/weather/forecast.html.erb
      format.json { render json: @forecast }
    end
  end
  
  def home
    # Renders app/views/weather/home.html.erb
  end
  
  private
  
  def address_params
    params.require(:address).permit(:city, :state, :street, :zip)
  end
  
  def get_forecast(zip)
    # Convert the zipcode into a latitude and longitude
    lat_lon = Geolocation::LocationService.get_lat_lon(zip)
    
    # Use the latitude and longitude to retrieve data about the weather for that location
    forecast = Weather::WeatherService.get_forecast(lat_lon)
    
    # Cache the forecast within Redis
    Rails.cache.write(
      { type: :weather_forecast, zip: zip },
      forecast,
      expires_in: CACHE_DURATION
    )
    
    # Return the forecast data
    forecast
  end
end
