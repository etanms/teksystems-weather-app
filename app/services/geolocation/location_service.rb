# frozen_string_literal: true

module Geolocation
  module LocationService
    def self.get_lat_lon(zip_code)
      # Retrieve data from Nominatim API for the given zipcode
      data = Nominatim.send_request(Nominatim::Endpoints::GET_LAT_LON, { zip: zip_code }).first
      # Format and return relevant data
      { lat: data['lat'], lon: data['lon'] }
    end
  end
end
