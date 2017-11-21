ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'

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

# MockParser to test env setter. Will return env['REQUEST_METHOD'] when called.
module MockParserWithEnvSetter
  def self.call(_body)
    @env['REQUEST_METHOD']
  end

  def self.env=(env)
    @env = env
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
