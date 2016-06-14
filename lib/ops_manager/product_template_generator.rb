class OpsManager
  class ProductTemplateGenerator
    OPS_MANAGER_PASSWORD_LENGTH = 20
    OPS_MANAGER_SALT_LENGTH = 16

    attr_reader :product_name

    def initialize(product_name)
      @product_name = product_name
    end

    def generate
      delete_partitions
      delete_vm_credentials
      delete_jobs_guid
      delete_prepared
      delete_ops_manager_generated_passwords
      delete_ops_manager_generated_salts
      add_merging_strategy_for_jobs

      { 'products' => [ "(( merge on guid ))" , selected_product ] }.to_yaml
        .gsub('"(( merge on guid ))"', '(( merge on guid ))')
        .gsub('"(( merge on identifier ))"', '(( merge on identifier ))')
    end

    private
    def delete_ops_manager_generated_passwords
      delete_value_from_properties_if do |value|
        value.fetch('password', '').length == OPS_MANAGER_PASSWORD_LENGTH
      end
    end

    def delete_ops_manager_generated_salts
      delete_value_from_properties_if do |value|
        value.fetch('salt', '').length == OPS_MANAGER_SALT_LENGTH
      end
    end

    def delete_value_from_properties_if
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
