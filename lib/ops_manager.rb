require 'ops_manager/api/opsman'
require 'net/ping'
require 'forwardable'
require 'ops_manager/configs/product_deployment'
require 'ops_manager/configs/opsman_deployment'

class OpsManager
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

    def set_conf(key, val)
      conf = {}
      Dir.mkdir(ops_manager_dir) unless Dir.exists?(ops_manager_dir)
      conf = YAML.load_file(conf_file_path) if File.exists?(conf_file_path)
      puts "Changing #{key} to #{val}".yellow unless conf[key].nil?
      conf[key] = val
      File.open(conf_file_path, 'w'){|f| f.write(conf.to_yaml) }
    end

    def get_conf(key)
      conf = {}
      conf = YAML.load_file(conf_file_path) if File.exists?(conf_file_path)
      conf[ key ]
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

  def deploy(config_file)
    config = OpsManager::Configs::OpsmanDeployment.new(::YAML.load_file(config_file))

    self.class.set_conf(:target, config.ip)
    self.class.set_conf(:username, config.username)
    self.class.set_conf(:password, config.password)
    self.class.set_conf(:pivnet_token, config.pivnet_token)

    @deployment ||= OpsManager::Deployments::Vsphere.new(config.name, config.version, config.opts)

    desired_version = OpsManager::Semver.new(deployment.desired_version)
    current_version = OpsManager::Semver.new(deployment.current_version)

    case

    when current_version.empty?
      puts "No OpsManager deployed at #{target}. Deploying ...".green
      deployment.deploy
    when current_version < desired_version then
      puts "OpsManager at #{target} version is #{current_version}. Upgrading to #{desired_version}.../".green
      deployment.upgrade
    when current_version == desired_version then
      puts "OpsManager at #{target} version is already #{desired_version}. Skiping ...".green
    end
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

  def self.ops_manager_dir
    "#{ENV['HOME']}/.ops_manager"
  end

  def self.conf_file_path
    "#{ops_manager_dir}/conf.yml"
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
