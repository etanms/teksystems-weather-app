require "rails_helper"

RSpec.describe Geolocation::LocationService do
  describe ".get_lat_lon" do
    let(:zip_code) { 95148 }
    
    # Mock response from Nominatim
    let(:nominatim_response) do
      [
        { 'lat' => '37.3293', 'lon' => '-121.891' }
      ]
    end
    
    before do
      # Stub Nominatim.send_request to avoid network calls
      allow(Geolocation::Nominatim).to receive(:send_request).and_return(nominatim_response)
    end
    
    it "calls Nominatim.send_request with correct endpoint and arguments" do
      Geolocation::LocationService.get_lat_lon(zip_code)
      
      expect(Geolocation::Nominatim).to have_received(:send_request).with(
        Geolocation::Nominatim::Endpoints::GET_LAT_LON,
        { zip: zip_code }
      )
    end
    
    it "returns a hash with lat and lon" do
      result = Geolocation::LocationService.get_lat_lon(zip_code)
      
      expect(result).to eq({ lat: '37.3293', lon: '-121.891' })
    end
  end
end
