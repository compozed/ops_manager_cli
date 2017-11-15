class OpsManager
  class DirectorTemplateGenerator
    def generate
      merge_director_template_products

    %w{ installation_schema_version ip_assignments guid }.each do |property_name|
      installation_settings.delete(property_name)
    end

    %w{ director_ssl uaa_ssl credhub_ssl uaa_credentials uaa_admin_user_credentials
      uaa_admin_client_credentials }.each do |property_name|
      product_template["products"].select {|p| p["identifier"] == "p-bosh"}.first.delete(property_name)
    end

      add_merging_strategy_for_networks

      installation_settings.to_h
    end

    def generate_yml
      generate.to_yaml
        .gsub('"(( merge on name ))"', '(( merge on name ))')
        .gsub('"(( merge on identifier ))"', '(( merge on identifier ))')
    end

    private
    def installation_settings
      return @installation_settings if @installation_settings
      res = OpsManager::Api::Opsman.new(silent: true).get_installation_settings
      @installation_settings = JSON.parse(res.body)
    end

    def merge_director_template_products
      installation_settings.merge!('products' => product_template.fetch('products'))
    end

    def add_merging_strategy_for_networks
      installation_settings['infrastructure']['networks'].tap do |networks|
        networks.unshift("(( merge on name ))") if networks
      end
    end

    def product_template
      @product_template ||= OpsManager::ProductTemplateGenerator.new('p-bosh').generate
    end
  end
end
