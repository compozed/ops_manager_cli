class OpsManager
  attr_accessor :deployment

  def self.target(target)
    set_conf(target: target)
  end


  def self.login(username, password)
    set_conf(username: username, password: password)
  end

  def self.set_conf(opts)
    conf = {}
    Dir.mkdir(ops_manager_dir) unless Dir.exists?(ops_manager_dir)
    conf = YAML.load_file(conf_file_path) if File.exists?(conf_file_path)
    conf.merge!(opts)
    File.open(conf_file_path, 'w'){|f| f.write(conf.to_yaml) }
  end

  def self.get_conf(key)
    conf = YAML.load_file(conf_file_path) if File.exists?(conf_file_path)
    conf.fetch(key)
  end

  def deploy(ops_manager_deployment_file)
    @ops_manager_deployment_file = ops_manager_deployment_file

    case provider
    when 'vsphere'
      @deployment ||= Vsphere.new(ops_manager_deployment_conf.fetch('name'), target, username, password, deployment_opts)
    end
    case
    when deployment.current_version.nil?
      puts "No OpsManager deployed at #{target}. Deploying ...".green
      deployment.deploy
    when deployment.current_version < new_version then
      puts "OpsManager at #{target} version is #{deployment.current_version}. Upgrading to #{new_version}.../".green
      deployment.upgrade
    when deployment.current_version ==  new_version then
      puts "OpsManager at #{target} version is already #{new_version}. Skiping ...".green
    end
  end

  def new_version
    deployment_opts.fetch('version')
  end

  private
  def provider
    ops_manager_deployment_conf.fetch('provider')
  end

  def deployment_opts
    @deployment_opts ||= ops_manager_deployment_conf.fetch('opts')
  end

  def ops_manager_deployment_conf
    @ops_manager_deployment_conf ||= ::YAML.load_file(@ops_manager_deployment_file)
  end

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
