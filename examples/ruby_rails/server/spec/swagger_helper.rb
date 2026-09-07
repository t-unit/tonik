ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/application'
require 'rspec/rails'
require 'rswag/specs'
require_relative 'schemas'

RSpec.configure do |config|
  config.fail_if_no_examples = true
  config.openapi_root = Rails.root.join('openapi').to_s
  config.openapi_specs = {
    'v1/openapi.json' => {
      openapi: '3.0.3',
      info: { title: 'Rails catalog', version: '1.0.0' },
      servers: [{ url: 'http://localhost' }],
      paths: {},
      components: { schemas: SCHEMAS }
    }
  }
  config.openapi_format = :json
end
