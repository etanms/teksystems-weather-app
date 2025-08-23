# Load the Rails application.
require_relative 'application'

# Require all files for extending existing classes
Dir[Rails.root.join('lib/extensions/*.rb')].each { |file| require file }

# Initialize the Rails application.
Rails.application.initialize!
