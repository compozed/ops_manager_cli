require 'ops_manager/api'
require "ops_manager/logging"
require 'byebug'

class OpsManager
  class Product
    include OpsManager::Logging

    def self.api
      target = OpsManager.get_conf(:target)
      username = OpsManager.get_conf(:username)

      password = OpsManager.get_conf(:password)
      @api ||= OpsManager::API.new(target, username, password )
    end

    attr_reader :name , :version, :filepath

    def initialize (name, version, filepath)
      @name, @version, @filepath = name, version, filepath
    end

    def upload
      file = "#{Dir.pwd}/#{filepath}"
      target= OpsManager.get_conf(:target)
      username = OpsManager.get_conf(:username)
      password = OpsManager.get_conf(:password)

      cmd = "curl -k \"https://#{target}/api/products\" -F 'product[file]=@#{file}' -X POST -u #{username}:#{password}"
      logger.info "running cmd: #{cmd}"
      puts `#{cmd}` unless self.class.exists?(name, version)


      # self.class.api.multipart_post( "/api/products",
      # :password => password,
      # "product[file]" => File.new("#{Dir.pwd}/#{filepath}")
      # )
    end

    def delete_unused_products
      self.class.api.delete('/api/products')
    end

    def deploy
    end

    def upgrade
      upload
      perform_upgrade
    end

    def perform_deploy
    end

    def self.exists?(name, version)
      products = JSON.parse( api.get('/api/products').body )
      !!products.find{ |o| o['name'] == name && o['product_version'] == version }
    end
  end
end
