class OpsManager
  class DirectorTemplateGenerator
    def generate
      merge_director_template_products
      delete_schema_version
      delete_director_ssl
      delete_uaa_ssl
      delete_guid
      delete_ip_assignments
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
      parsed_installation_settings = JSON.parse(installation_settings_response.body)
      @installation_settings = OpsManager::InstallationSettings.new(parsed_installation_settings)
    end

    def merge_director_template_products
      installation_settings.merge!('products' => product_template.fetch('products'))
    end

    def add_merging_strategy_for_networks
      installation_settings['infrastructure']['networks'].tap do |networks|
        networks.unshift("(( merge on name ))") if networks
      end
    end

    def delete_schema_version
      @installation_settings.delete('installation_schema_version')
    end

    def delete_ip_assignments
      @installation_settings.delete('ip_assignments')
    end

    def delete_guid
      @installation_settings.delete('guid')
    end

    def delete_director_ssl
      product_template["products"][1].delete("director_ssl")
    end

    def delete_uaa_ssl
      product_template["products"][1].delete("uaa_ssl")
    end

    def product_template
      @product_template ||= OpsManager::ProductTemplateGenerator.new('p-bosh').generate
    end


    def installation_settings_response
      OpsManager::Api::Opsman.new(silent: true).get_installation_settings
    end
  end
end
