require "rails_helper"

RSpec.describe Weather::WeatherService do
  describe ".get_forecast" do
    let(:args) { { lat: 37.3293, lon: -121.891 } }
    
    # Stubbed JSON strings to work with String#as_hash
    let(:location_response_body) do
      '{"properties":{"gridId":"MTR","gridX":103,"gridY":81}}'
    end
    
    let(:forecast_response_body) do
      '{
        "properties":{
          "periods":[
            {"name":"Today","temperature":75},
            {"name":"Tonight","temperature":60}
          ]
        }
      }'
    end
    
    # Mock HTTParty responses
    let(:location_response) { instance_double("HTTParty::Response", body: location_response_body) }
    let(:forecast_response) { instance_double("HTTParty::Response", body: forecast_response_body) }
    
    before do
      # Stub the NationalWeatherService calls
      allow(Weather::NationalWeatherService).to receive(:send_request)
                                                  .with(Weather::NationalWeatherService::Endpoints::GET_LOCATION_DATA, args)
                                                  .and_return(location_response)
      
      allow(Weather::NationalWeatherService).to receive(:send_request)
                                                  .with(
                                                    Weather::NationalWeatherService::Endpoints::GET_HOURLY_FORECAST,
                                                    { grid_id: "MTR", x: 103, y: 81 }
                                                  )
                                                  .and_return(forecast_response)
    end
    
    it "calls NationalWeatherService with correct endpoints and arguments" do
      Weather::WeatherService.get_forecast(args)
      
      expect(Weather::NationalWeatherService).to have_received(:send_request)
                                                   .with(Weather::NationalWeatherService::Endpoints::GET_LOCATION_DATA, args)
      
      expect(Weather::NationalWeatherService).to have_received(:send_request)
                                                   .with(
                                                     Weather::NationalWeatherService::Endpoints::GET_HOURLY_FORECAST,
                                                     { grid_id: "MTR", x: 103, y: 81 }
                                                   )
    end
    
    it "returns the periods array from the forecast response" do
      result = Weather::WeatherService.get_forecast(args)
      
      expect(result["properties"]["periods"]).to eq([
                                                      { "name" => "Today", "temperature" => 75 },
                                                      { "name" => "Tonight", "temperature" => 60 }
                                                    ])
    end
  end
end
