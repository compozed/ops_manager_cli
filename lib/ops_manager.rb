require 'ops_manager/api/opsman'
require 'net/ping'
require 'forwardable'
require 'session_config'
require 'ops_manager/configs/product_deployment'
require 'ops_manager/configs/opsman_deployment'

class OpsManager
  extend SessionConfig

  class << self
    def target(target)
      @target = target
      if target_is_pingable?
        set_conf(:target, target)
      else
        puts "Can not connect to #{target}".red
      end
    end

    def login(username, password)
      set_conf(:username, username)
      set_conf(:password, password)
    end

    def target_and_login(target, username, password)
      target(target) if target
      login(username, password) if username && password
    end

    private
    def target_is_pingable?
      Net::Ping::HTTP.new("https://#{@target}").ping?
    end
  end

  private
  def target
    self.class.get_conf(:target)
  end

  def username
    self.class.get_conf(:username)
  end

  def password
    self.class.get_conf(:password)
  end
end



require "ops_manager/version"
require "ops_manager/semver"
require "ops_manager/deployments/vsphere"
require "ops_manager/cli"
require "ops_manager/errors"
require "colorize"
require "net/https"
require "uri"
require "json"
require "yaml"
