$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ops_manager_deployer'

RSpec.configure do |config|
  config.before :suite do
    Dir.chdir('spec/dummy')
  end
end

