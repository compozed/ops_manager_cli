require 'logger'
require 'byebug'

class OpsManager
  module Logging
    def logger
      Logging.logger
    end

    def self.logger
      @logger ||= Logger.new(STDOUT,log_level)
    end

    def self.logger=(l)
      @logger = l
    end

    private
    def self.log_level
      if ENV['DEBUG'].nil?
        Logger::WARN
      else
        Logger::INFO
      end
    end
  end
end
