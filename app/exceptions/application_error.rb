# frozen_string_literal: true

class ApplicationError < StandardError
  attr_reader :message, :status
  
  DEFAULT_STATUS  = :internal_server_error
  DEFAULT_MESSAGE = "An unexpected error occurred. Please try again later."
  private_constant(:DEFAULT_STATUS, :DEFAULT_MESSAGE)
  
  def initialize(message: self.class::MESSAGE || DEFAULT_MESSAGE, status: self.class::STATUS || DEFAULT_STATUS)
    # Set internal variables
    @message = message
    @status  = status
    
    # Return the newly created exception
    super(message)
  end
end
