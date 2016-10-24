require 'ops_manager/api/opsman'
require 'ops_manager/product_installation'
require 'ops_manager/installation_runner'
require "ops_manager/logging"
require "ops_manager/semver"

class OpsManager
  class ProductDeployment
    extend Forwardable
    def_delegators :opsman_api, :current_version, :upload_product, :get_installation_settings,
      :upgrade_product_installation, :get_installation, :get_available_products, :upload_installation_settings,
      :trigger_installation, :import_stemcell, :add_staged_products

    include OpsManager::Logging

    def initialize(config_file, forced_deployment = false)
      @config_file = config_file
      @forced_deployment = forced_deployment
    end

    def installation
      OpsManager::ProductInstallation.find(config.name)
    end

    def run
      OpsManager.target_and_login(config.target, config.username, config.password)
      import_stemcell(config.stemcell)

      case
      when installation.nil? || forced_deployment?
        deploy
      when installation && installation.current_version < desired_version
        upgrade
      when installation && installation.current_version == desired_version
        deploy
      end
    end

    def desired_version
      Semver.new(config.desired_version)
    end

    def upload
      print "====> Uploading product ...".green
      if ProductDeployment.exists?(config.name, config.desired_version)
        puts "product already exists".green
      elsif config.filepath
        upload_product(config.filepath)
        puts "done".green
      else
        puts "no filepath provided, skipping product upload.".green
      end
    end

    def upgrade
      unless installation.prepared?
        puts "====> Skipping as this product has a pending installation!".red
        return
      end
      puts "====> Upgrading #{config.name} version from #{installation.current_version.to_s} to #{config.desired_version}...".green
      upload
      upgrade_product_installation(installation.guid, config.desired_version)
      merge_product_installation_settings
      OpsManager::InstallationRunner.trigger!.wait_for_result

      puts "====> Finish!".green
    end

    def add_to_installation
      unless installation
        add_staged_products(config.name, config.desired_version)
      end
    end

    def deploy
      puts "====> Deploying #{config.name} version #{config.desired_version}...".green
      upload
      add_to_installation
      merge_product_installation_settings
      OpsManager::InstallationRunner.trigger!.wait_for_result

      puts "====> Finish!".green
    end


    def merge_product_installation_settings
      get_installation_settings({write_to: '/tmp/is.yml'})
      puts `DEBUG=false spruce merge /tmp/is.yml #{config.installation_settings_file} > /tmp/new_is.yml`
      upload_installation_settings('/tmp/new_is.yml')
    end

    def self.exists?(name, version)
      res = JSON.parse(OpsManager::Api::Opsman.new.get_available_products.body)
      !!res.find{ |o| o['name'] == name && o['product_version'].include?(version) }
    end

    private
    def desired_version
      @desired_version ||= OpsManager::Semver.new(config.desired_version)
    end

    def forced_deployment?
      !!@forced_deployment
    end

    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def config
      OpsManager::Configs::ProductDeployment.new(::YAML.load_file(@config_file))
    end
  end
end
