require 'ops_manager/api'
require 'net/ping'

class OpsManager
  attr_accessor :deployment
  include OpsManager::Api

  class Version < Array
    def initialize s
      return unless s
      super(s.split('.').map { |e| e.to_i })
    end

    def < x
      (self <=> x) < 0
    end

    def > x
      (self <=> x) > 0
    end

    def == x
      (self <=> x) == 0
    end

    def to_s
      self.join('.')
    end
  end

  class << self
    def target(target)
      if Net::Ping::HTTP.new("https://#{target}").ping?

        set_conf(:target, target)
      else
        puts "Can not connect to #{target}".red
      end
    end

    def login(username, password)
      set_conf(:username, username)
      set_conf( :password, password)
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
  end

  def target_and_login(config)
    username = config['username']
    password = config['password']
    target = config['target']

    self.class.target(target) if target
    self.class.login(username, password) if username && password
  end

  def deploy(conf_file)
    conf = ::YAML.load_file(conf_file)

    name = conf.fetch('name')
    provider = conf.fetch('provider')
    username = conf.fetch('username')
    password = conf.fetch('password')
    target = conf.fetch('ip')
    opts = conf.fetch('opts')

    self.class.set_conf(:target, target)
    self.class.set_conf(:username, username)
    self.class.set_conf(:password, password)
    @deployment ||= OpsManager.const_get(provider.capitalize).new(name, conf.fetch('version'), opts)

    desired_version = OpsManager::Version.new(deployment.desired_version)
    current_version = OpsManager::Version.new(deployment.current_version)

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

  def deploy_product(conf_file, force = false)
    conf = ::YAML.load_file(conf_file)
    target_and_login(conf)
    name = conf.fetch('name')
    version = conf.fetch('version')
    filepath = conf['filepath']
    stemcell = conf['stemcell']
    installation_settings_file = conf['installation_settings_file']

    product = OpsManager::Product.new(name)
    import_stemcell(stemcell)
    product.deploy(version, filepath, installation_settings_file, force)
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
end



require "ops_manager/version"
require "ops_manager/vsphere"
require "ops_manager/cli"
require "ops_manager/errors"
require "colorize"
require "net/https"
require "uri"
require "json"
require "yaml"
