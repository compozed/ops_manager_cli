require 'ops_manager/api/opsman'
require 'net/ping'
require 'forwardable'
require 'session_config'
require 'ops_manager/configs/product_deployment'
require 'ops_manager/configs/opsman_deployment'

class OpsManager
  extend SessionConfig
  extend Forwardable
  attr_accessor :deployment
  def_delegators :opsman_api, :current_version, :import_stemcell


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


    private
    def target_is_pingable?
      Net::Ping::HTTP.new("https://#{@target}").ping?
    end
  end

  def target_and_login(config)
    username = config['username']
    password = config['password']
    target = config['target']

    self.class.target(target) if target
    self.class.login(username, password) if username && password
  end


  def deploy_product(config_file, force = false)
    config = OpsManager::Configs::ProductDeployment.new(::YAML.load_file(config_file))
    target_and_login({username: config.username, password: config.password })
    product = OpsManager::Product.new(config.name)
    import_stemcell(config.stemcell)
    product.deploy(config.version, config.filepath, config.installation_settings_file, force)
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

  def opsman_api
    @opsman_api ||= OpsManager::Api::Opsman.new
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
