require "ops_manager/api/opsman"
require "ops_manager/api/pivnet"
require "ops_manager/installation_settings"
require 'ops_manager/configs/opsman_deployment'

class OpsManager::ApplianceDeployment
  extend Forwardable
  def_delegators :pivnet_api, :download_stemcell
  def_delegators :opsman_api, :create_user, :trigger_installation, :get_installation_assets,
    :get_installation_settings, :get_diagnostic_report, :upload_installation_assets,
    :import_stemcell, :target, :password, :username, :ops_manager_version=

  attr_reader :config_file

  def initialize(config_file)
    @config_file = config_file
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
      create_first_user
    when current_version < desired_version then
      puts "OpsManager at #{target} version is #{current_version}. Upgrading to #{desired_version}.../".green
      upgrade
    when current_version == desired_version then
      puts "OpsManager at #{target} version is already #{config.desired_version}. Skiping ...".green
    end
  end

  def deploy
    deploy_vm(desired_vm_name , config.ip)
  end

  %w{ stop_current_vm deploy_vm }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end

  def create_first_user
    puts '====> Creating initial user...'.green
    until( create_user.code.to_i == 200) do
      print '.'.green ; sleep 1
    end
  end

  def upgrade
    get_installation_assets
    get_installation_settings(write_to: 'installation_settings.json')
    stop_current_vm(current_vm_name)
    deploy
    upload_installation_assets
    provision_missing_stemcells
    OpsManager::InstallationRunner.trigger!.wait_for_result

    puts "====> Finish!".green
  end


  def new_vm_name
    @new_vm_name ||= "#{config.name}-#{config.desired_version}"
  end

  def current_version
    @current_version ||= OpsManager::Semver.new(version_from_diagnostic_report)
  end

  def desired_version
    @desired_version ||= OpsManager::Semver.new(config.desired_version)
  end

  private

  def diagnostic_report
    @diagnostic_report ||= get_diagnostic_report
  end

  def version_from_diagnostic_report
    return unless diagnostic_report
    version = parsed_diagnostic_report
      .fetch("versions")
      .fetch("release_version")
    version.gsub(/.0$/,'')
  end

  def parsed_diagnostic_report
    JSON.parse(diagnostic_report.body)
  end

  def current_vm_name
    @current_vm_name ||= "#{config.name}-#{current_version}"
  end

  def desired_vm_name
    @desired_vm_name ||= "#{config.name}-#{config.desired_version}"
  end

  def provision_missing_stemcells
    puts '====> Reprovisioning missing stemcells...'.green
    installation_settings.stemcells.each do |s|
      download_stemcell(s.fetch(:version), s.fetch(:file), /vsphere/)
      import_stemcell(s.fetch(:file))
    end
  end

  def pivnet_api
    @pivnet_api ||= OpsManager::Api::Pivnet.new
  end

  def opsman_api
    @opsman_api ||= OpsManager::Api::Opsman.new
  end

  def config
    parsed_yml = ::YAML.load_file(@config_file)
    @config ||= OpsManager::Configs::OpsmanDeployment.new(parsed_yml)
  end

  def installation_settings
    @installation_settings ||= OpsManager::InstallationSettings.new(parsed_installation_settings)
  end

  def parsed_installation_settings
    JSON.parse(File.read('installation_settings.json'))
  end

  def desired_version?(version)
    !!(desired_version.to_s =~/#{version}/)
  end
end
