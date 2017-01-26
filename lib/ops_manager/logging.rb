require 'logger'

class OpsManager
  module Logging
    def logger
      Logging.logger
    end

    def self.logger
      @logger ||= Logger.new(STDOUT).tap do |l|
        l.level = log_level
      end
    end

    def self.logger=(logger)
      @logger = logger
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
