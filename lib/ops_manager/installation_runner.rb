class OpsManager
  class InstallationRunner
    extend Forwardable
    def_delegators :opsman_api, :trigger_installation, :get_installation, :get_current_version,
      :get_staged_products, :get_staged_products_errands
    attr_reader :id

    def trigger!
      res = trigger_installation( body: body.join('&') )
      @id = JSON.parse(res.body).fetch('install').fetch('id').to_i
      self
    end

    def self.trigger!
      new.trigger!
    end

    def wait_for_result
      while JSON.parse(get_installation(id).body).fetch('status') == 'running'
        print '.'.green
        sleep 10
      end
      puts ''
    end

    private
    def body
      @body ||= [ 'ignore_warnings=true' ]
      @body << errands_body

      @body
    end

    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def errands_body
      staged_products_guids.collect do |product_guid|
        post_deploy_errands_body_for(product_guid)
      end
    end

    def post_deploy_errands_body_for(product_guid)
      post_deploy_errands = post_deploy_errands_for(product_guid)

      unless post_deploy_errands.empty?
        post_deploy_errands.collect{ |e| "enabled_errands[#{product_guid}][post_deploy_errands][]=#{e}" }
      else
        "enabled_errands[#{product_guid}]{}"
      end
    end

    def staged_products_guids
      staged_products.collect {|product| product.fetch('guid') }
    end

    def staged_products
      JSON.parse(get_staged_products.body)
    end

    def post_deploy_errands_for(product_guid)
      errands_for(product_guid).keep_if{ |errand| errand['post_deploy'] }.map{ |o| o['name']}
    end

    def errands_for(product_guid)
      res = get_staged_products_errands(product_guid)
      if res.code == 200
        JSON.parse(res.body)['errands']
      else
        []
      end
    end
  end
end
