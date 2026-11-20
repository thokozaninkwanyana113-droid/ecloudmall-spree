ENV['RAILS_ENV'] ||= 'test'

begin
  require File.expand_path('../dummy/config/environment', __FILE__)
rescue LoadError
  puts 'Could not load dummy application. Please ensure you have run `bundle exec rake test_app`'
  exit
end

require 'rspec/rails'
require 'database_cleaner/active_record'
require 'ffaker'
require 'webmock/rspec'

require 'spree/testing_support/factories'
require 'spree/testing_support/jobs'
require 'spree/testing_support/store'
require 'spree/api/testing_support/v3/base'
require 'spree/api/testing_support/factories'

Dir[File.dirname(__FILE__) + '/{factories,support}/**/*.rb'].each { |f| require f }

def json_response
  JSON.parse(response.body).with_indifferent_access
end

RSpec.configure do |config|
  config.color = true
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    Spree::Events.disable!
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    I18n.locale = :en
    Spree::Current.reset
  end

  config.include(Module.new do
    extend ActiveSupport::Concern
    included { routes { Spree::Core::Engine.routes } }
  end, type: :controller)

  config.order = :random
end
