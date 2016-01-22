require 'ops_manager/api'

class OpsManager
  class ProductInstallation
    attr_reader :guid, :version
    include OpsManager::API

    def initialize(guid, version)
      @guid, @version = guid, version
    end


    def self.find(name)
      res = self.new('', '').get('/api/installation_settings')
      parsed_res = JSON.parse(res.body)
      products = parsed_res.fetch('products')
      product = products.select{|o| o.fetch('identifier') == name }.first

      new(product.fetch('guid'), product.fetch('product_version')) if product
    end
  end
end
