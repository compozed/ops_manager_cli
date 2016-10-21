class OpsManager
  class ProductTemplateGenerator
    OPS_MANAGER_PASSWORD_LENGTH = 32
    OPS_MANAGER_SECRET_LENGTH = 32
    OPS_MANAGER_SALT_LENGTH = 14

    attr_reader :product_name

    def initialize(product_name)
      @product_name = product_name
    end

    def generate
      %w{ prepared guid installation_name product_version stemcell }.each do |property_name|
        delete_from_product(property_name)
      end

      %w{ partitions vm_credentials guid }.each do |property_name|
      delete_from_jobs(property_name)
      end

      %w{ password secret salt private_key_pem }.each do |property_name|
        delete_value_from_job_properties(property_name)
      end

      %w{ secret private_key_pem }.each do |property_name|
        delete_value_from_product_properties(property_name)
      end

      add_merging_strategy_for_jobs
      add_merging_strategy_for_job_properties

      { 'products' => [ "(( merge on identifier ))" , selected_product ] }
    end

    def generate_yml
      generate.to_yaml
        .gsub('"(( merge on identifier ))"', '(( merge on identifier ))')
    end

    private

    def add_merging_strategy_for_jobs
      selected_product['jobs'].unshift("(( merge on identifier ))")
    end

    def add_merging_strategy_for_job_properties
      selected_product['jobs'].each do |j|
        j['properties'].unshift("(( merge on identifier ))") if j['properties']
      end
    end

    def delete_from_product(name)
      selected_product.delete(name)
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
      return @installation_settings if @installation_settings
      res = OpsManager::Api::Opsman.new(silent: true).get_installation_settings
      @installation_settings = JSON.parse(res.body)
    end

    def delete_value_from_product_properties(name)
      selected_product.fetch('properties', []).each  do |p|
        value = p.fetch('value',{})
        p.delete('value') if value.is_a?(Hash) && !!value[name]
      end
    end

    def delete_value_from_job_properties(name)
      selected_product['jobs'].each do |j|
        j.fetch('properties', []).each  do |p|
          value = p.fetch('value',{})
          p.delete('value') if value.is_a?(Hash) && !!value[name]
        end
      end
    end
  end
end
