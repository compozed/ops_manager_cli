class OpsManager
  class ProductTemplateGenerator
    OPS_MANAGER_PASSWORD_LENGTH = 20
    OPS_MANAGER_SECRET_LENGTH = 20
    OPS_MANAGER_SALT_LENGTH = 16

    attr_reader :product_name

    def initialize(product_name)
      @product_name = product_name
    end


    def generate
      delete_partitions
      delete_vm_credentials
      delete_guid
      delete_jobs_guid
      delete_prepared
      delete_ops_manager_generated_passwords
      delete_ops_manager_generated_salts
      delete_ops_manager_generated_secrets
      delete_private_key_pem
      delete_product_version
      add_merging_strategy_for_jobs

      { 'products' => [ "(( merge on identifier ))" , selected_product ] }
    end

    def generate_yml
      generate.to_yaml
        .gsub('"(( merge on guid ))"', '(( merge on guid ))')
        .gsub('"(( merge on identifier ))"', '(( merge on identifier ))')
    end

    private
    def delete_product_version
      delete_value_from_product_properties_if do |property|
        property['identifier'] == 'product_version'
      end
    end

    def delete_ops_manager_generated_passwords
      delete_value_from_job_properties_if do |value|
        value.fetch('password', '').length == OPS_MANAGER_PASSWORD_LENGTH
      end
    end

    def delete_private_key_pem
      delete_value_from_product_properties_if do |property|
        property['value'].is_a?(Hash) && property['value'].has_key?('private_key_pem')
      end

      delete_value_from_job_properties_if do |value|
        value.fetch('secret', '').length == OPS_MANAGER_SECRET_LENGTH
        value.has_key?('private_key_pem')
      end
    end

    def delete_ops_manager_generated_salts
      delete_value_from_job_properties_if do |value|
        value.fetch('salt', '').length == OPS_MANAGER_SALT_LENGTH
      end
    end

    def delete_ops_manager_generated_secrets
      delete_value_from_product_properties_if do |property|
        property['value'].is_a?(Hash) && property['value'].fetch('secret', '').length == OPS_MANAGER_SECRET_LENGTH
      end

      delete_value_from_job_properties_if do |value|
        value.fetch('secret', '').length == OPS_MANAGER_SECRET_LENGTH
      end
    end

    def delete_value_from_product_properties_if
      selected_product.fetch('properties', []).each  do |p|
        p.delete('value') if p.is_a?(Hash) && yield(p)
      end
    end

    def delete_value_from_job_properties_if
      selected_product['jobs'].each do |j|
        j.fetch('properties', []).each  do |p|
          value = p.fetch('value',{})
          p.delete('value') if value.is_a?(Hash) && yield(value)
        end
      end
    end

    def delete_prepared
      selected_product.delete("prepared")
    end

    def delete_guid
      selected_product.delete("guid")
    end

    def add_merging_strategy_for_jobs
      selected_product['jobs'].unshift("(( merge on identifier ))")
    end

    def delete_partitions
      delete_from_jobs('partitions')
    end

    def delete_vm_credentials
      delete_from_jobs('vm_credentials')
    end

    def delete_jobs_guid
      delete_from_jobs('guid')
    end

    def selected_product
      @selected_product ||= products.select {|p| p.fetch('identifier') == product_name }.first
    end

    def products
      installation_settings.fetch('products')
    end

    def delete_from_jobs(key)
      selected_product.tap do |sp|
        sp['jobs'].each{ |j| j.delete(key) }
      end
    end

    def installation_settings
      parsed_installation_settings = JSON.parse(installation_settings_response.body)
      OpsManager::InstallationSettings.new(parsed_installation_settings)
    end

    def installation_settings_response
      OpsManager::Api::Opsman.new(silent: true).get_installation_settings
    end
  end
end
