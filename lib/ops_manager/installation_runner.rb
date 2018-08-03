class OpsManager
  class InstallationRunner
    extend Forwardable
    def_delegators :opsman_api, :trigger_installation, :get_installation,
      :get_staged_products, :get_staged_products_errands
    attr_reader :id

    def trigger!(products = "all")
      res = trigger_installation( :headers => {"Content-Type"=>"application/json"}, :body => body(products))
      @id = JSON.parse(res.body).fetch('install').fetch('id').to_i
      self
    end

    def self.trigger!(products = "all")
      new.trigger!(products)
    end

    def wait_for_result
      while JSON.parse(get_installation(id).body).fetch('status') == 'running'
        print ' .'.green
        sleep 10
      end
      puts ''
    end

    private
    def body(products)
      b = {'errands' => errands(products), 'ignore_warnings' => true }
      if products != "all"
        b["deploy_products"] = products
      end
      @body ||= b.to_json
    end
    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def errands(products)
      res = { }

      if products == "none"
        return res
      end

      if products == "all"
        products = staged_products_guids
      end
      products.each do |product_guid|
        errands = errands_for(product_guid).keep_if { |an_errand| an_errand['post_deploy'] }
        errands.each { |e| res[product_guid] = {'run_post_deploy' => { e['name'] => true}}}
      end
      res
    end

    def staged_products_guids
      staged_products.collect {|product| product.fetch('guid') }
    end

    def staged_products
      JSON.parse(get_staged_products.body)
    end


    def errands_for(product_guid)
      res = get_staged_products_errands(product_guid)

      if res.code == '200'
        JSON.parse(res.body)['errands']
      else
        []
      end
    end
  end
end
