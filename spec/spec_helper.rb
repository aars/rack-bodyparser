ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'pry'
# require 'simplecov'
# SimpleCov.start

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rack/bodyparser'

# MockParser to test :patch_request option.
module MockParser
  # custom getter key
  def self.rack_request_key
    :mockparser_document
  end

  def self.call(_body)
    'mockparser called!'
  end
end

module MockLogger
  def self.warn(_msg)
    'you were warned!'
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end