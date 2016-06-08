class OpsManager
  class ProductTemplateGenerator
    attr_reader :product_name

    def initialize(product_name)
      @product_name = product_name
    end

    def generate
      {
        'products' => [
          "(( merge on guid ))" ,
          installation_settings.fetch('products').select do |p|
            p.fetch('identifier') == product_name
          end.first
        ]
      }.to_yaml
    end

    private
    def installation_settings
      parsed_installation_settings = JSON.parse(installation_settings_response.body)
      OpsManager::InstallationSettings.new(parsed_installation_settings)
    end

    def installation_settings_response
      OpsManager::Api::Opsman.new(silent: true).get_installation_settings
    end
  end
end
