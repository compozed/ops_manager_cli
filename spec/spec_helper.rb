$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ops_manager_deployer'
require 'vcr'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before :suite do
    Dir.chdir('spec/dummy')
  end
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end


