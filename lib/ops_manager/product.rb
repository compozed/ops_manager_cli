require 'ops_manager/api'

class OpsManager
  class Product
    include OpsManager::API
    attr_reader :name , :filepath

    def initialize (name, filepath)
      @name, @filepath = name, filepath
    end

    def list
      get('/api/products')
    end
  end
end
