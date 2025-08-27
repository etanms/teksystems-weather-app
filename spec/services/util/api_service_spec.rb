require "rails_helper"

RSpec.describe Util::ApiService do
  # Define a test implementation class for testing the module
  class FakeApi
    extend Util::ApiService
    
    BASE_URL = "https://example.com"
    HEADERS  = { "User-Agent": "FakeApi/1.0" }
    
    module Endpoints
      TEST_ENDPOINT = :test_endpoint
    end
    
    class << self
      def test_endpoint(args)
        {
          body:  args[:body],
          query: { bar: args[:bar] },
          path: "/foo"
        }
      end
    end
  end
  
  let(:mock_response) { double("HTTParty::Response") }
  
  before do
    # Stub HttpService to prevent real HTTP requests
    allow(Util::Http::HttpService).to receive(:send_request).and_return(mock_response)
  end
  
  describe "#send_request" do
    it "calls the endpoint method and forwards arguments to HttpService" do
      args = { bar: "baz", body: { x: 1 } }
      
      result = FakeApi.send_request(FakeApi::Endpoints::TEST_ENDPOINT, args)
      
      # Expect HttpService.send_request to have been called with a hash including the built URL and options
      expect(Util::Http::HttpService).to have_received(:send_request) do |hash|
        expect(hash[:url]).to eq("https://example.com/foo")
        expect(hash[:options][:query]).to eq({ bar: "baz" })
        expect(hash[:options][:body]).to eq(JSON.generate({ x: 1 }))
        expect(hash[:options][:headers]).to eq(JSON.parse(FakeApi::HEADERS.to_json))
      end
      
      # Expect the result to be the mocked response
      expect(result).to eq(mock_response)
    end
  end
end
