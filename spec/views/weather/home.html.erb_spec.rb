# spec/views/weather/home.html.erb_spec.rb
require "rails_helper"

RSpec.describe "weather/home.html.erb", type: :view do
  before do
    # Explicitly render the template to avoid lookup issues
    render template: "weather/home"
  end
  
  it "displays the page title" do
    expect(rendered).to match /Weather Forecast by Address/
  end
  
  it "includes a form with the correct action and method" do
    expect(rendered).to have_selector("form[action='#{weather_forecast_path}'][method='get']")
  end
  
  it "has input fields for street, city, state, and zip code" do
    expect(rendered).to have_field("address[street]")
    expect(rendered).to have_field("address[city]")
    expect(rendered).to have_field("address[state]")
    expect(rendered).to have_field("address[zip]")
  end
  
  it "requires the zip code field and applies the correct pattern and title" do
    zip_input = Nokogiri::HTML(rendered).at_css("input#zip")
    expect(zip_input["required"]).to eq("required")
    expect(zip_input["pattern"]).to eq("\\d{5}(-\\d{4})?")
    expect(zip_input["title"]).to eq("Please enter a valid 5-digit or 9-digit ZIP code")
  end
  
  
  it "has a submit button and a reset button" do
    expect(rendered).to have_selector("input[type='submit'][value='Get Forecast']")
    expect(rendered).to have_selector("button[type='reset']", text: "Reset")
  end
end
