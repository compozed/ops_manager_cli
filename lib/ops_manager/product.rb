require 'ops_manager/api/opsman'
require 'ops_manager/product_installation'
require 'ops_manager/installation'
require "ops_manager/logging"

class OpsManager
  class Product
    extend Forwardable

    def_delegators :opsman_api, :current_version, :upload_product, :get_installation_settings,
      :upgrade_product_installation, :get_installation, :get_products, :upload_installation_settings,
      :trigger_installation

    include OpsManager::Logging

    attr_reader :name

    def initialize(name = nil)
      @name = name
    end

    def installation
      OpsManager::ProductInstallation.find(name)
    end

    def deploy(version, filepath, installation_settings_file, forced = false)
      case
      when installation.nil? || forced
        perform_new_deployment(version, filepath, installation_settings_file)
      when installation && installation.version < version
        perform_upgrade(version, filepath)
      when installation && installation.version == version
        perform_new_deployment(version, filepath, installation_settings_file)
      end
    end

    def upload(version, filepath)
      puts "====> Uploading product...".green
      unless self.class.exists?(name, version)
        upload_product(filepath)
        print "done".green
      else
        print "product already exists".green
      end
    end

    # make me private? maybe?
    def perform_upgrade(version, filepath)
      unless installation.prepared?
        puts "====> Skipping as this product has a pending installation!".red
        return
      end
      puts "====> Upgrading #{name} version from #{installation.version} to #{version}...".green
      upload(version, filepath)
      upgrade_product_installation(installation.guid, version)
      OpsManager::Installation.trigger!.wait_for_result

      puts "====> Finish!".green
    end

    def perform_new_deployment(version,  filepath,installation_settings_file)
      puts "====> Deploying #{name} version #{version}...".green
      upload(version, filepath)
      get_installation_settings({write_to: '/tmp/is.yml'})
      puts `DEBUG=false spruce merge /tmp/is.yml #{installation_settings_file} > /tmp/new_is.yml`
      upload_installation_settings('/tmp/new_is.yml')
      OpsManager::Installation.trigger!.wait_for_result

      puts "====> Finish!".green
    end

    def self.exists?(name, version)
      res = JSON.parse(self.new.get_products.body)
      !!res.find{ |o| o['name'] == name && o['product_version'] == version }
    end


    private
    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end
  end
end
