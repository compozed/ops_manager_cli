$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ops_manager'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before :suite do
    Dir.chdir('spec/dummy')
    ENV['HOME'] = ENV['PWD']
  end
end
