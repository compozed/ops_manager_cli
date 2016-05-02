require "ops_manager/api/opsman"
require "ops_manager/api/pivnet"
require "ops_manager/installation_settings"

class OpsManager::Deployments
  class Base
    extend Forwardable
    def_delegators :pivnet_api, :download_stemcell
    def_delegators :opsman_api, :create_user, :trigger_installation, :get_installation_assets,
      :get_installation_settings, :upload_installation_assets, :import_stemcell, :target,
      :password, :username, :get_current_version

    def initialize(config_file)
      @config_file = config_file
    end

    %w{ stop_current_vm deploy_vm }.each do |m|
      define_method(m) do
        raise NotImplementedError
      end
    end

    def deploy
      deploy_vm
      create_first_user
    end

    def create_first_user
      puts '====> Creating initial user...'.green
      until( create_user(config.desired_version).code.to_i == 200) do
        print '.'.green ; sleep 1
      end
    end

    def upgrade
      get_installation_assets
      get_installation_settings(write_to: 'installation_settings.json')
      stop_current_vm(current_vm_name)
      deploy(new_vm_name, config.ip)
      provision_missing_stemcells
      upload_installation_assets
      OpsManager::Installation.trigger!.wait_for_result

      puts "====> Finish!".green
    end


    def new_vm_name
      @new_vm_name ||= "#{config.name}-#{config.desired_version}"
    end

    private
    def current_version
      @current_version ||= OpsManager::Semver.new(get_current_version)
    end

    def desired_version
      @desired_version ||= OpsManager::Semver.new(config.desired_version)
    end

    def current_vm_name
      @current_vm_name ||= "#{config.name}-#{current_version}"
    end

    def provision_missing_stemcells
      installation_settings.stemcells.each do |s|
        download_stemcell(s.fetch(:version), s.fetch(:file), /vsphere/)
        import_stemcell(s.fetch(:file))
      end
    end

    def installation_settings
      @installation_settings ||= OpsManager::InstallationSettings.new('installation_settings.json')
    end

    def pivnet_api
      @pivnet_api ||= OpsManager::Api::Pivnet.new
    end

    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def config
      @config ||= OpsManager::Configs::OpsmanDeployment.new(::YAML.load_file(@config_file))
    end
  end
end