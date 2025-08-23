# spec/requests/weather_spec.rb
require "rails_helper"

RSpec.describe "Weather requests", type: :request do
  let(:zip) { 90210 }
  let(:forecast_data) do
    [
      { "number" => 1, "name" => "Today", "temperature" => 92, "shortForecast" => "Sunny" },
      { "number" => 2, "name" => "Tonight", "temperature" => 60, "shortForecast" => "Clear" }
    ]
  end
  let(:record) { { cached_at: DateTime.now, forecast: forecast_data } }
  
  before do
    # Stub the private get_forecast method to avoid API calls
    allow_any_instance_of(WeatherController)
      .to receive(:get_forecast)
            .with(zip)
            .and_return(record)
    
    # Stub Rails.cache.fetch to use our record
    allow(Rails.cache).to receive(:fetch).and_return(record)
  end
  
  describe "GET /weather" do
    it "renders the home page successfully" do
      get "/weather"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weather Forecast by Address")
    end
  end
  
  describe "GET /weather/forecast" do
    context "HTML format" do
      #TODO
      # it "renders the forecast page with cached data" do
      #   get "/weather/forecast", params: { address: { zip: zip } }
      #   expect(response).to have_http_status(:ok)
      #   expect(response.body).to include("Sunny")  # Example of forecast in HTML
      # end
    end
    
    context "JSON format" do
      it "returns forecast as JSON" do
        get "/weather/forecast", params: { address: { zip: zip } }, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to eq(forecast_data)
      end
    end
    
    context "caching behavior" do
      it "reads from Rails.cache if present" do
        cache_key = { type: :weather_forecast, zip: zip }
        expect(Rails.cache).to receive(:fetch).with(cache_key).and_return(record)
        get "/weather/forecast", params: { address: { zip: zip } }
      end
    end
  end
end
