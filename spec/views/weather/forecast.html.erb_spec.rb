require "rails_helper"

RSpec.describe "weather/forecast", type: :view do
  let(:cached_at) { Time.new(2025, 8, 26, 12, 0, 0, "+00:00") }
  
  let(:forecast_data) do
    {
      Date.today => {
        temperature_sum: 150,
        num_periods: 2,
        high: 80,
        low: 70,
        humidity_sum: 120,
        precipitation_pct: 20,
        forecast: {
          "Sunny" => { count: 2, icon: "http://example.com/sunny.png" },
          "Cloudy" => { count: 1, icon: "http://example.com/cloudy.png" }
        },
        periods: [
          {
            "startTime" => (Time.now + 1.hour).iso8601,
            "temperature" => 75,
            "relativeHumidity" => { "value" => 50 },
            "windDirection" => "NW",
            "windSpeed" => "10 mph",
            "shortForecast" => "Sunny",
            "icon" => "http://example.com/sunny.png"
          },
          {
            "startTime" => (Time.now + 2.hours).iso8601,
            "temperature" => 76,
            "relativeHumidity" => { "value" => 55 },
            "windDirection" => "N",
            "windSpeed" => "12 mph",
            "shortForecast" => "Partly Cloudy",
            "icon" => "http://example.com/partly_cloudy.png"
          }
        ]
      }
    }
  end
  
  before do
    assign(:cached_at, cached_at)
    assign(:forecast, forecast_data)
    render
  end
  
  it "displays the cached timestamp" do
    expect(rendered).to match(/Cached At: #{cached_at.localtime.strftime("%Y-%m-%d %H:%M:%S")}/)
  end
  
  it "renders a card for each day" do
    forecast_data.each_key do |date|
      expect(rendered).to have_css(".card[data-date='#{date}']")
      expect(rendered).to match(/#{date.strftime("%A, %b %d, %Y")}/)
    end
  end
  
  it "renders the dominant forecast condition and icon" do
    forecast_data.each do |date, data|
      dominant_condition, details = data[:forecast].max_by { |_, v| v[:count] }
      expect(rendered).to have_css("img[src='#{details[:icon]}'][alt='#{dominant_condition} icon']")
      expect(rendered).to match(/#{dominant_condition}/)
    end
  end
  
  it "renders a table row for each hourly period" do
    forecast_data.each do |_, data|
      data[:periods].each do |period|
        expect(rendered).to match(/#{period["temperature"]}/)
        expect(rendered).to match(/#{period["relativeHumidity"]["value"]}/)
        expect(rendered).to match(/#{period["windDirection"]} #{period["windSpeed"]}/)
        expect(rendered).to match(/#{period["shortForecast"]}/)
        expect(rendered).to have_css("img[src='#{period['icon']}'][alt='#{period['shortForecast']}']")
      end
    end
  end
  
  context "when forecast is empty" do
    before do
      assign(:forecast, {})
      render
    end
    
    it "displays a no forecast message" do
      expect(rendered).to match(/No forecast data available/)
    end
  end
end
