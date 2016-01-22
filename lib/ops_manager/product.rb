require 'ops_manager/api'
require 'ops_manager/product_installation'
require "ops_manager/logging"
require 'byebug'

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
      upgrade
    end

    def upgrade(version, filepath)
      upload(version, filepath)
      upgrade_product_installation(installation.guid, version)
      trigger_installation
    end

    def perform_deploy
    end


    def self.exists?(name, version)
      !!self.new.get_products.find{ |o| o['name'] == name && o['product_version'] == version }
    end
  end
end
