class OpsManager
  attr_accessor :deployment

  class << self
    def target(target)
      set_conf(target: target)
    end

    def login(username, password)
      set_conf(username: username, password: password)
    end

    def set_conf(opts)
      conf = {}
      Dir.mkdir(ops_manager_dir) unless Dir.exists?(ops_manager_dir)
      conf = YAML.load_file(conf_file_path) if File.exists?(conf_file_path)
      conf.merge!(opts)
      File.open(conf_file_path, 'w'){|f| f.write(conf.to_yaml) }
    end

    def get_conf(key)
      conf = YAML.load_file(conf_file_path) if File.exists?(conf_file_path)
      conf.fetch(key)
    end
  end

  def deploy(conf_file)
    conf = ::YAML.load_file(conf_file)
    name = conf.fetch('name')
    version = conf.fetch('version')
    provider=conf.fetch('provider')
    opts = conf.fetch('opts')

    case provider
    when 'vsphere'
      @deployment ||= Vsphere.new(name, version, opts)
    end
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
    product = OpsManager::Product.new(name, version, filepath)
    product.deploy
  end

  # def new_version
    # deployment_opts.fetch('version')
  # end

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
