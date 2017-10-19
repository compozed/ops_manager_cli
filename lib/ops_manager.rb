require 'net/ping'
require 'forwardable'
require 'session_config'

class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end
end

class OpsManager
  extend SessionConfig

  class << self
    extend Forwardable
    def_delegators :opsman_api, :get_token

    def show_status
      authenticated = !!opsman_api.get_token ? 'YES'.green : 'NO'.red

      [
        "Target: #{self.get_conf(:target).green}",
        "Authenticated: #{authenticated}"
      ].join("\n")
    end

    def set_target(uri)
      if target_is_pingable?(uri)
        set_conf(:target, uri)
      else
        puts "Can not connect to #{uri}".red
      end
    end

    def login(username, password)
      set_conf(:username, username)
      set_conf(:password, password)
      opsman_api.get_token
    end

    def target_and_login(uri, username, password)
      self.set_target(uri) if uri
      login(username, password) if username && password
    end

    private
    def opsman_api
      OpsManager::Api::Opsman.new
    end

    def target_is_pingable?(uri)
      Net::Ping::HTTP.new("https://#{uri}/docs").ping?
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
require "ops_manager/appliance/vsphere"
require "ops_manager/appliance/aws"
require 'ops_manager/configs/product_deployment'
require 'ops_manager/configs/opsman_deployment'
require "ops_manager/cli"
require "ops_manager/errors"
require "net/https"
require "uri"
require "json"
require "yaml"
