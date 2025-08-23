# frozen_string_literal: true

module Util
  class MissingRequiredParameterError < ApplicationError
    MESSAGE = 'Required parameter is missing or invalid. Please provide all necessary fields.'
    STATUS  = :bad_request
  end
end
