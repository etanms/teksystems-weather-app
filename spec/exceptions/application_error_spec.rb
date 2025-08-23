# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationError do
  describe "#initialize" do
    context "when no custom message or status is provided" do
      let(:error) { described_class.new }
      
      it "uses the default message" do
        expect(error.message).to eq(described_class.const_get(:DEFAULT_MESSAGE))
      end
      
      it "uses the default status" do
        expect(error.status).to eq(described_class.const_get(:DEFAULT_STATUS))
      end
    end
    
    context "when a custom message and status are provided directly" do
      let(:error) { described_class.new(message: "Something broke", status: :bad_request) }
      
      it "overrides the default message" do
        expect(error.message).to eq("Something broke")
      end
      
      it "overrides the default status" do
        expect(error.status).to eq(:bad_request)
      end
    end
  end
  
  describe "subclass behavior" do
    # Define a test subclass inline
    class FakeError < ApplicationError
      MESSAGE = "Something specific failed"
      STATUS  = :unprocessable_entity
    end
    
    let(:error) { FakeError.new }
    
    it "uses the subclass MESSAGE constant" do
      expect(error.message).to eq(FakeError::MESSAGE)
    end
    
    it "uses the subclass STATUS constant" do
      expect(error.status).to eq(FakeError::STATUS)
    end
  end
end
