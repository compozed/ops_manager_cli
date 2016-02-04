require 'ops_manager/api'
require 'ops_manager/product_installation'
require "ops_manager/logging"

class OpsManager
  class Product
    include OpsManager::Logging
    include OpsManager::API

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
      when installation
        perform_upgrade(version, filepath)
      end
    end

    def upload(version, filepath)
      upload_product(filepath) unless self.class.exists?(name, version)
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
      trigger_installation
      puts "====> Finish!".green
    end

    def perform_new_deployment(version,  filepath,installation_settings_file)
      puts "====> Deploying #{name} version #{version}...".green
      upload(version, filepath)
      get_installation_settings({write_to: '/tmp/is.yml'})
      puts `spruce merge #{installation_settings_file} /tmp/is.yml > /tmp/new_is.yml`
      upload_installation_settings('/tmp/new_is.yml')
      trigger_installation
    end


    def self.exists?(name, version)
      res = JSON.parse(self.new.get_products.body)
      !!res.find{ |o| o['name'] == name && o['product_version'] == version }
    end


  end
end
