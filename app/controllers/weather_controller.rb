# frozen_string_literal: true

class WeatherController < ApplicationController
  CACHE_DURATION = 30.minutes
  private_constant(:CACHE_DURATION)
  
  def forecast
    # Extract zip code
    validate_zip(params[:address][:zip])
    zip = address_params[:zip].to_i
    
    # Attempt to retrieve the forecast from the cache, or retrieve it from API if not recently cached
    record = Rails.cache.fetch({ type: :weather_forecast, zip: zip }) || get_forecast(zip)
    
    @cached_at = record[:cached_at]
    @forecast  = record[:forecast]
    
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
  
  def formatted_forecast(data)
    # Retrieve the list of time periods within the data
    periods = data['properties']['periods']
    
    # Use HashMap lookup to store the high/low temperatures for each day
    forecast_data = {}
    periods.each do |period|
      # Determine the date for this time period
      date = (period['startTime'].to_datetime + 1.second).localtime.to_date
      # Set default values for this date if necessary
      forecast_data[date] = {
        forecast:          {},
        humidity_sum:      0,
        num_periods:       0,
        periods:           [],
        precipitation_pct: 0,
        temperature_sum:   0,
        wind_direction:    {},
        wind_speed_sum:    0
      } if forecast_data[date].nil?
      # Increment the count of total periods for this date
      forecast_data[date][:num_periods] += 1
      
      # Determine the forecast for this time period
      forecast = period['shortForecast']
      # Retrieve the currently stored object for this specific forecast
      current_data = forecast_data[date][:forecast][forecast]
      # Setup initial forecast object containing a counter and a display icon
      current_data = { count: 0, icon: period['icon'] } if current_data.nil?
      # Increment the count of how many times the forecast for this time period has occurred
      current_data[:count] += 1
      # Update the icon to a daytime icon
      current_data[:icon] = period['icon'] if period['isDaytime']
      # Replace current forecast object with the updated object
      forecast_data[date][:forecast][forecast] = current_data
      
      # Determine the humidity for this time period
      humidity = period['relativeHumidity']['value']
      # Add the humidity to the sum used later to determine the average
      forecast_data[date][:humidity_sum] += humidity
      
      # Determine the probability of precipitation for this time period
      precipitation_pct = period['probabilityOfPrecipitation']['value']
      # Add the probability of precipitation to the sum used later to determine the average
      forecast_data[date][:precipitation_pct] += precipitation_pct
      
      # Determine the temperature for this time period
      temp = period['temperature']
      # Add this temperature to the sum used later to determine the average
      forecast_data[date][:temperature_sum] += temp
      
      # Store the temperature for this time period as the high if necessary
      current_high               = forecast_data.dig(date, :high)
      forecast_data[date][:high] = temp if current_high.nil? || temp > current_high
      # Store the temperature for this time period as the low if necessary
      current_low                = forecast_data.dig(date, :low)
      forecast_data[date][:low]  = temp if current_low.nil? || temp < current_low
      
      # Determine the wid direction for this time period
      wind_direction = period['windDirection']
      # Increment the count of how many times the wind direction for this time period has occurred
      current_count = forecast_data.dig(date, :wind_direction, wind_direction) || 0
      forecast_data[date][:wind_direction][wind_direction] = current_count + 1
      
      # Determine the wind speed for this time period
      wind_speed = period['windSpeed'].split.first.to_i
      # Add this wind speed to the sum used later to determine the average
      forecast_data[date][:wind_speed_sum] += wind_speed
      
      # Store the entire period record within the date object
      forecast_data[date][:periods] = forecast_data.dig(date, :periods).push(period)
    end
    
    # Return the forecast data
    forecast_data
  end
  
  def get_forecast(zip)
    # Convert the zipcode into a latitude and longitude
    lat_lon = Geolocation::LocationService.get_lat_lon(zip)
    
    # Use the latitude and longitude to retrieve data about the weather for that location
    forecast = Weather::WeatherService.get_forecast(lat_lon)
    
    # Format the data with the current time so the time it was cached at can be referenced in the future
    record = { cached_at: DateTime.now, forecast: formatted_forecast(forecast) }
    
    # Cache the forecast within Redis
    Rails.cache.write(
      { type: :weather_forecast, zip: zip },
      record,
      expires_in: CACHE_DURATION
    )
    
    # Return the forecast data
    record
  end
  
  def validate_zip(zip)
    # Raise error if nil
    raise ArgumentError, "address.zip is required" if zip.nil?
    
    # Allow integers
    return if zip.is_a?(Integer)
    
    # Allow strings that can be safely converted to integer
    return if zip.is_a?(String) && zip.strip.match?(/\A\d+\z/)
    
    # Otherwise, raise an exception
    raise ArgumentError, "address.zip must be an integer or numeric string."
  end
end
