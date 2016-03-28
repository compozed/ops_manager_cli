require "ops_manager/api/opsman"
require "ops_manager/api/pivnet"
require "ops_manager/installation_settings"

class OpsManager::Deployments
  class Base
    extend Forwardable
    def_delegators :pivnet_api, :download_stemcell
    def_delegators :opsman_api, :create_user


    attr_accessor :name, :desired_version

    def initialize(name,  desired_version)
      @name, @desired_version = name, desired_version
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
      until( create_user(desired_version).code.to_i == 200) do
        print '.'.green ; sleep 1
      end
    end

    def upgrade
      get_installation_assets
      get_installation_settings(write_to: 'installation_settings.json')
      stop_current_vm
      deploy
      provision_missing_stemcells
      upload_installation_assets
      puts "====> Finish!".green
    end

    def new_vm_name
      @new_vm_name ||= "#{name}-#{desired_version}"
    end

    private
    def current_vm_name
      @current_vm_name ||= "#{name}-#{current_version}"
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
  end
end
