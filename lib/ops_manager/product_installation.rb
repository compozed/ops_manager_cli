require 'ops_manager/api'

class OpsManager
  class ProductInstallation
    attr_reader :guid, :version

    def initialize(guid, version, prepared)
      @guid, @version, @prepared = guid, version, prepared
    end

    def prepared?
      @prepared
    end

    class << self
    include OpsManager::Api
      def find(name)
        is = installation_settings_for(name)
        new(
          is.fetch('guid'),
          is.fetch('product_version'),
          is.fetch('prepared')
        ) if is
      end

      private

      def installation_settings_for(name)
        res = get_installation_settings
        parsed_res = JSON.parse(res.body)
        products = parsed_res.fetch('products')
        products.select{|o| o.fetch('identifier') == name }.first
      end
    end
  end
end
