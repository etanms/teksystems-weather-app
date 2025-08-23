# frozen_string_literal: true

class MethodNotSupportedError < ApplicationError
  MESSAGE = 'The HTTP method for this request is not supported.'
  STATUS  = :method_not_allowed
end
