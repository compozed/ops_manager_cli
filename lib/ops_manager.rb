class OpsManager
  attr_accessor :deployment

  def initialize(conf_file)
    @conf_file = conf_file

    case provider
    when 'vsphere'
      @deployment = Vsphere.new(conf.fetch('name'), conf.fetch('ip'), conf.fetch('username'), conf.fetch('password'), deployment_opts)
    end
  end


  def deploy
      case
      when deployment.current_version.nil?
        puts "No OpsManager deployed at #{conf.fetch('ip')}. Deploying ...".green
        deployment.deploy
      when deployment.current_version < new_version then
        puts "OpsManager at #{conf.fetch('ip')} version is #{deployment.current_version}. Upgrading to #{new_version}.../".green
        deployment.upgrade
      when deployment.current_version ==  new_version then
        puts "OpsManager at #{conf.fetch('ip')} version is already #{new_version}. Skiping ...".green
      end
  end

  def new_version
    deployment_opts.fetch('version')
  end

  private

  def provider
    deployment_config.fetch('provider')
  end

  def deployment_config
    @deployment_config ||= conf.fetch('deployment')
  end

  def deployment_opts
    @deployment_opts ||= deployment_config.fetch('opts')
  end

  def conf
    @conf ||= ::YAML.load_file(@conf_file)
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
