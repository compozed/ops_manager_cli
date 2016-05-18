$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ops_manager'
require 'vcr'
require 'webmock/rspec'

RSpec.configure do |config|
  # config.before :all do
    # @orig_stdout = $stdout
    # @orig_stderr = $stderr

    # $stdout = File.open(File::NULL, "w")
    # $stderr = File.open(File::NULL, "w")
  # end

  # config.after :all do
   # $stdout = @orig_stdout
   # $stderr = @orig_stderr
  # end

  config.before :suite do
    Dir.chdir('spec/dummy')
    ENV['HOME'] = ENV['PWD']
  end
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.allow_http_connections_when_no_cassette = true
  config.hook_into :webmock
end

