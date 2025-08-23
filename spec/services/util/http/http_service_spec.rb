# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('app/services/util/http/http_service')


RSpec.describe Util::Http::HttpService, type: :service do
  before do
    # Allow logger to receive logs
    allow(Rails.logger).to receive(:info)
  end

  describe '#method_supported?' do
    context 'when the method is supported' do
      # List through valid methods and check that they pass method_supported?
      described_class::RequestMethods.constants.each do |const|
        method = described_class::RequestMethods.const_get(const)
        it "returns true for #{method.upcase} requests" do
          expect(described_class.send(:method_supported?, method)).to be_truthy
        end
      end
    end

    context 'when the method is not supported' do
      # Check that method_supported? returns false
      it 'will return false' do
        expect(described_class.send(:method_supported?, "fake")).to be_falsey
      end
    end
  end

  describe '#log_request' do
    # Mock request arguments
    let(:url) { "https://api.example.com" }
    let(:method) { described_class::RequestMethods::POST }
    let(:time) { DateTime.new(2024, 10, 15, 12, 30) }

    context 'when all parameters are provided' do
      # Mock the request
      let(:options) do
        {
          body: {
            "name" => "John Doe",
            "email" => "john@example.com",
            "password" => "securepassword123"
          },
          headers: {
            "Authorization" => "Bearer sample_token",
            "Content-Type" => "application/json"
          },
          query: { "limit" => 10, "offset" => 20 }
        }
      end

      it 'will log the request with all parameters' do
        # Send request and check that it logs correctly
        described_class.log_request(url, method, options, time)
        expect(Rails.logger).to have_received(:info) do |log_message|
          expect(log_message).to match(/URL:\s*#{url}/)
          expect(log_message).to match(/METHOD:\s*#{method.upcase}/)
          expect(log_message).to match(/CURRENT TIME:\s*#{time.strftime('%Y-%m-%d %H:%M:%S')}/)
          expect(log_message).to match(/#{options[:headers]["Authorization"]}/)
          expect(log_message).to match(/#{options[:headers]["Content-Type"]}/)
          expect(log_message).to match(/#{options[:body]["name"]}/)
          expect(log_message).to match(/#{options[:body]["email"]}/)
          expect(log_message).to match(/#{options[:body]["password"]}/)
        end
      end
    end

    context 'when the body is a string' do
      # Mock the request with the body being a string
      let(:options) do
        {
          body: '{
            "name": "John Doe",
            "email": "john@example.com",
            "password": "securepassword123"
          }'
        }
      end

      it 'will properly convert body to hash and display it' do
        # Send request and check that it logs correctly
        described_class.log_request(url, method, options, time)
        expect(Rails.logger).to have_received(:info) do |log_message|
          expect(log_message).to match(/#{options[:body]["name"]}/)
          expect(log_message).to match(/#{options[:body]["email"]}/)
          expect(log_message).to match(/#{options[:body]["password"]}/)
        end
      end
    end


    context 'when the body is empty' do
      # Mock the request with no body
      let(:options) do
        {
          headers: {
            "Authorization" => "Bearer sample_token",
            "Content-Type" => "application/json"
          }
        }
      end
      
      it 'will fill body with empty {}' do
        # Check that the request properly logs the empty body
        described_class.log_request(url, method, options, time)
        expect(Rails.logger).to have_received(:info) do |log_message|
          expect(log_message).to match(/BODY:\s*{}/)
        end
      end
    end
  end

  describe '#log_response' do
    # Mock time and now for consistency
    let(:time) { DateTime.new(2024, 10, 15, 12, 30) }
    let(:now) { DateTime.new(2024, 10, 15, 12, 31) }

    # Mock the request
    let(:mock_request) do
      double(
        'Request',
        uri: 'http://test.com',
        last_uri: 'http://test.com/last',
        http_method: described_class::RequestMethods::GET
      )
    end

    # Allow datetime to return the consistent time
    before :each do
      allow(DateTime).to receive(:now).and_return(now)
    end

    context 'when all parameters are supported' do
      # Mock response
      let(:mock_response) do
        double(
          code: 200,
          message: 'OK',
          body: '{
            "key": "value"
          }',
          headers: { 'Content-Type' => 'application/json' },
          request: mock_request
        )
      end

      it 'will log the response' do
        # Check that the response gets logged correctly
        described_class.send(:log_response, mock_response, time)
        expect(Rails.logger).to have_received(:info) do |log_message|
          expect(log_message).to match(/CODE:\s*#{mock_response.code}/)
          expect(log_message).to match(/MESSAGE:\s*#{mock_response.message}/)
          expect(log_message).to match(/URL:\s*#{mock_request.uri}/)
          expect(log_message).to match(/LAST URL:\s*#{mock_request.last_uri}/)
          expect(log_message).to match(/METHOD:\s*#{mock_request.http_method}/)
          expect(log_message).to match(/TIME:\s*#{time.strftime('%Y-%m-%d %H:%M:%S')}/)
          expect(log_message).to match(/TIME ELAPSED:\s*#{(now.to_time - time.to_time).in_milliseconds} ms/)
          expect(log_message).to match(/HEADERS:\s*#{mock_response.headers.inspect}/)
          expect(log_message).to match(/#{JSON.parse(mock_response.body)}/)
        end
      end
    end

    context 'when the body cannot be converted to json' do
      # Mock non json formatted body in response
      let(:mock_response) do
        double(
          'Response',
          code: 200,
          message: 'OK',
          body: 'This is a non json body',
          headers: { 'Content-Type' => 'application/json' },
          request: mock_request
        )
      end
      
      it 'will display the body' do
        # Check that it still displays the body
        described_class.send(:log_response, mock_response, time)
        expect(Rails.logger).to have_received(:info) do |log_message|
          expect(log_message).to match(/BODY:\s*#{mock_response.body}/)
        end
      end
    end
  end

  describe '#send_request' do
    # Mock arguments
    let(:url) { 'http://example.com/api' }
    let(:bad_url) { 'http://some_bad_url.net]]' }
    let(:method) { described_class::RequestMethods::GET }
    let(:options) { { headers: { 'Content-Type' => 'application/json' } } }
    let(:mock_response) { double('Response', code: 200, message: 'OK', body: '{"data": "value"}') }

    # Mock methods tested above
    before do
      allow(described_class).to receive(:log_request)
      allow(described_class).to receive(:log_response)
      allow(HTTParty).to receive(:send).with(method, url, options).and_return(mock_response)
      allow(HTTParty).to receive(:send).with(method, bad_url, options).and_raise(URI::InvalidURIError)
    end

    context 'when the method is supported' do
      before do
        # Mock method_supported? to return true
        allow(described_class).to receive(:method_supported?).and_return(true)
      end
      it 'will return the response' do
        # Check that it returns the correct response
        response = described_class.send(:send_request, url: url, method: method, options: options)
        expect(response.code).to eq(mock_response.code)
        expect(response.message).to eq(mock_response.message)
        expect(response.body).to eq(mock_response.body)
      end

      context 'when the URL is incorrect' do
        it 'will error with invalid URI error message' do
          # Check that it properly handles the case where the url is wrong
          expect do
            described_class.send(:send_request, url: bad_url, method: method, options: options)
          end.to raise_error(URI::InvalidURIError)
        end
      end
    end

    context 'when the method is not supported' do
      before do
        # Mock method_supported? to return false
        allow(described_class).to receive(:method_supported?).and_return(false)
      end
      
      it 'will return an method not supported error' do
        # Check that it will raise a MethodNotSupported error
        expect { described_class.send(:send_request, url: url, method: method, options: options) }.to raise_error do |err|
          expect(err).to be_a(Util::Http::MethodNotSupportedError)
        end
      end
    end
  end
end