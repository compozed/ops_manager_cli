class OpsManager
  attr_accessor :deployment

  class << self
    def target(target)
      set_conf(:target, target)
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

  def deploy(conf_file)
    conf = ::YAML.load_file(conf_file)
    name = conf.fetch('name')
    version = conf.fetch('version')
    provider = conf.fetch('provider')
    username = conf.fetch('username')
    password = conf.fetch('password')
    target = conf.fetch('ip')
    opts = conf.fetch('opts')

    self.class.set_conf(:target, target)
    self.class.set_conf(:username, username)
    self.class.set_conf(:password, password)
      @deployment ||= const_get(provider).new(name, version, opts)
    case

    when deployment.current_version.nil?
      puts "No OpsManager deployed at #{target}. Deploying ...".green
      deployment.deploy
    when deployment.current_version < version then
      puts "OpsManager at #{target} version is #{deployment.current_version}. Upgrading to #{version}.../".green
      deployment.upgrade
    when deployment.current_version ==  version then
      puts "OpsManager at #{target} version is already #{version}. Skiping ...".green
    end
  end


  def deploy_product(conf_file)
    conf = ::YAML.load_file(conf_file)
    name = conf.fetch('name')
    version = conf.fetch('version')
    filepath = conf.fetch('filepath')
    product = OpsManager::Product.new(name)
    product.deploy(version, filepath)
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
require "colorize"
require "net/https"
require "uri"
require "json"
require "yaml"
