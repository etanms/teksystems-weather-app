# spec/controllers/weather_controller_private_spec.rb
require "rails_helper"

RSpec.describe WeatherController, type: :unit do
  let(:zip) { 90210 }
  let(:lat_lon) { { lat: 34.0901, lon: -118.4065 } }
  let(:forecast_data) do
    {
      "properties" => {
        "periods" => [
          {
            "name"                       => "Today",
            "number"                     => 1,
            "probabilityOfPrecipitation" => { "value" => 2 },
            "relativeHumidity"           => { "value" => 10 },
            "shortForecast"              => "Mostly Sunny",
            "startTime"                  => "2025-08-27T00:05:30.918Z",
            "temperature"                => 92,
            "windDirection"              => "N",
            "windSpeed"                  => "4 mph"
          }
        ]
      }
    }
  end
  
  before do
    # Mock Geolocation service
    allow(Geolocation::LocationService).to receive(:get_lat_lon).with(zip).and_return(lat_lon)
    # Mock Weather service
    allow(Weather::WeatherService).to receive(:get_forecast).with(lat_lon).and_return(forecast_data)
    # Mock caching
    allow(Rails.cache).to receive(:write)
  end
  
  describe "#get_forecast" do
    it "returns a record with forecast and cached_at" do
      record = described_class.new.send(:get_forecast, zip)
      
      expect(record).to have_key(:forecast)
      
      expected_forecast = {
        "2025-08-26".to_date => {
          forecast:          { "Mostly Sunny" => {count: 1, icon: nil} },
          high:              92,
          humidity_sum:      10,
          low:               92,
          num_periods:       1,
          periods:           [
                               {
                                 "name"                       => "Today",
                                 "number"                     => 1,
                                 "probabilityOfPrecipitation" => { "value" => 2 },
                                 "relativeHumidity"           => { "value" => 10 },
                                 "shortForecast"              => "Mostly Sunny",
                                 "startTime"                  => "2025-08-27T00:05:30.918Z",
                                 "temperature"                => 92,
                                 "windDirection"              => "N",
                                 "windSpeed"                  => "4 mph"
                               }
                             ],
          precipitation_pct: 2,
          temperature_sum:   92,
          wind_direction:    { "N" => 1 },
          wind_speed_sum:    4
        }
      }
      expect(record[:forecast]).to eq(expected_forecast)
      
      expect(record).to have_key(:cached_at)
      expect(record[:cached_at]).to be_a(DateTime)
    end
    
    it "writes the record to the cache" do
      record = described_class.new.send(:get_forecast, zip)
      
      expect(Rails.cache).to have_received(:write).with(
        { type: :weather_forecast, zip: zip },
        record,
        expires_in: WeatherController.const_get(:CACHE_DURATION)
      )
    end
  end
  
  describe "#validate_zip" do
    # Use an anonymous controller to call the private method
    let(:controller_instance) do
      Class.new(WeatherController) do
        def call_validate(zip)
          validate_zip(zip)
        end
      end.new
    end
    
    it "allows integer zip codes" do
      expect { controller_instance.call_validate(12345) }.not_to raise_error
    end
    
    it "allows numeric strings" do
      expect { controller_instance.call_validate("90210") }.not_to raise_error
      expect { controller_instance.call_validate(" 90210 ") }.not_to raise_error
    end
    
    it "raises an error for nil" do
      expect { controller_instance.call_validate(nil) }.to raise_error(ArgumentError, /address\.zip is required/)
    end
    
    it "raises an error for non-numeric strings" do
      expect { controller_instance.call_validate("abc") }.to raise_error(ArgumentError, /address\.zip must be an integer or numeric string/)
    end
    
    it "raises an error for floats" do
      expect { controller_instance.call_validate(90210.5) }.to raise_error(ArgumentError, /address\.zip must be an integer or numeric string/)
    end
    
    it "raises an error for arrays" do
      expect { controller_instance.call_validate([90210]) }.to raise_error(ArgumentError, /address\.zip must be an integer or numeric string/)
    end
  end
end
