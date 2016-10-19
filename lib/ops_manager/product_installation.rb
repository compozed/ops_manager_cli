require 'ops_manager/api/opsman'

class OpsManager
  class ProductInstallation
    attr_reader :guid

    def initialize(guid, version, prepared)
      @guid, @version, @prepared = guid, version, prepared
    end

    def prepared?
      @prepared
    end

    def current_version
      Semver.new(@version)
    end

    class << self
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
        res = opsman_api.get_installation_settings
        parsed_res = JSON.parse(res.body)
        products = parsed_res.fetch('products')
        products.select{|o| o.fetch('identifier') == name }.first
      end

      def opsman_api
        @opsman_api = OpsManager::Api::Opsman.new(silent: true)
      end
    end
  end
end
