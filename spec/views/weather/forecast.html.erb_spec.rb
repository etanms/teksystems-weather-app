# spec/views/weather/forecast.html.erb_spec.rb
require "rails_helper"
require "nokogiri"
require "erb"

RSpec.describe "weather/forecast.html.erb", type: :view do
  let(:cached_at) { DateTime.new(2025, 8, 23, 12, 0, 0) }
  let(:forecast_data) do
    [
      {
        "number" => 1,
        "name" => "Today",
        "startTime" => "2025-08-23T12:00:00-04:00",
        "endTime" => "2025-08-23T18:00:00-04:00",
        "temperature" => 85,
        "temperatureUnit" => "F",
        "probabilityOfPrecipitation" => { "value" => 10 },
        "windSpeed" => "5 mph",
        "windDirection" => "NW",
        "shortForecast" => "Sunny",
        "detailedForecast" => "Clear skies throughout the day.",
        "icon" => "/path/to/sunny.png"
      }
    ]
  end
  
  before do
    # Assign instance variables like a controller would
    @forecast = forecast_data
    @cached_at = cached_at
    
    # Load template and render it with binding
    template_path = Rails.root.join("app/views/weather/forecast.html.erb")
    template_string = File.read(template_path)
    @rendered_html = ERB.new(template_string).result(binding)
    @doc = Nokogiri::HTML(@rendered_html)
  end
  
  it "displays the page title" do
    expect(@doc.at_css("title").text).to eq("Weather Forecast")
  end
  
  it "shows the cached time" do
    local_time_str = cached_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(@doc.at_css("header h4").text).to include("Cached At: #{local_time_str}")
  end
  
  it "renders each forecast period in a card" do
    cards = @doc.css("main .container .card")
    expect(cards.count).to eq(forecast_data.size)
    
    first_card = cards.first
    expect(first_card.at_css("h2").text).to eq("Today")
    expect(first_card.at_css(".details p strong").text).to eq("Temperature:")
    expect(first_card.at_css(".details p").text).to include("85°F")
    expect(first_card.at_css(".icon img")["alt"]).to eq("Sunny icon")
  end
  
  it "renders a message when no forecast data is present" do
    @forecast = []
    template_path = Rails.root.join("app/views/weather/forecast.html.erb")
    template_string = File.read(template_path)
    rendered_empty = ERB.new(template_string).result(binding)
    doc_empty = Nokogiri::HTML(rendered_empty)
    
    expect(doc_empty.at_css("main p").text).to eq("No forecast data available.")
  end
end
