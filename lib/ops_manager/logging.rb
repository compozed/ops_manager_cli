require 'logger'

class OpsManager
  module Logging
    def logger
      Logging.logger
    end

    def self.logger
      @logger ||= Logger.new( ENV['DEBUG'].nil? ? 'ops_manager.log' : STDOUT)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
