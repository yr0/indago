require 'bundler/setup'
require_relative '../lib/indago'

WITHIN_TEST_DIR = ->(target) { File.join(File.dirname(__FILE__), *target) }
Dir.glob(File.join(File.dirname(__FILE__), 'support', '**', '*.rb')).each { |f| require f }

RSpec.configure do |config|
  include IndagoSpecHelper

  config.before(:each) do
    # These directories have fixed content and ARE NOT supposed to be modified during testing. If you want to test
    # creating data or indexes by modifying them, stub these constants to randomly-unique names, like SecureRandom.uuid,
    # per each test. You can use :tmp_dirs context for this.
    # This approach will allow the tests to be run in random order and in parallel.
    stub_const 'Indago::DATA_DIR_PATH', WITHIN_TEST_DIR.call(%w[fixtures data])
    # Suppress all Indago logger output by default
    stub_const 'Indago::LOGGER_LEVEL', 10
    # you should re-stub this const in your tests to spec/tmp/<uniquely-random-name>
    stub_const 'Indago::INDEXES_DIR_PATH', '/dev/null'
  end

  config.order = :random
  Kernel.srand config.seed

  # Default options for next version of RSpec (4)
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  def available_collections
    %w[users organizations tickets]
  end
end
