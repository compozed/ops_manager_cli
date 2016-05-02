require "ops_manager/api/opsman"
require "ops_manager/api/pivnet"
require "ops_manager/installation_settings"
require 'ops_manager/configs/opsman_deployment'
require 'byebug'

class OpsManager::Deployment < OpsManager::Deployments::Base
  def initialize(config_file)
    super(config_file)
  end

  def run
    OpsManager.set_conf(:target, config.ip)
    OpsManager.set_conf(:username, config.username)
    OpsManager.set_conf(:password, config.password)
    OpsManager.set_conf(:pivnet_token, config.pivnet_token)

    self.extend(OpsManager::Deployments::Vsphere)

    case
    when current_version.empty?
      puts "No OpsManager deployed at #{target}. Deploying ...".green
      deploy
    when current_version < desired_version then
      puts "OpsManager at #{target} version is #{current_version}. Upgrading to #{desired_version}.../".green
      upgrade
    when current_version == desired_version then
      puts "OpsManager at #{target} version is already #{config.desired_version}. Skiping ...".green
    end
  end
  private

end
