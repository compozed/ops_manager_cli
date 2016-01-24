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

    def upload(version, filepath)
      file = "#{Dir.pwd}/#{filepath}"
      upload_product(file) unless self.class.exists?(name, version)
    end

    def deploy(version, filepath)
      upgrade(version, filepath)
    end

    def upgrade(version, filepath)
      puts "====> Upgrading #{name} version from #{installation.version} to #{version}...".green
      upload(version, filepath)
      upgrade_product_installation(installation.guid, version)
      trigger_installation
      puts "====> Finish!".green
    end

    def perform_deploy
    end


    def self.exists?(name, version)
      res = JSON.parse(self.new.get_products.body)
      !!res.find{ |o| o['name'] == name && o['product_version'] == version }
    end
  end
end
