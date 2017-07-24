class OpsManager
  class InstallationRunner
    extend Forwardable
    def_delegators :opsman_api, :trigger_installation, :get_installation,
      :get_staged_products, :get_staged_products_errands
    attr_reader :id

    def trigger!
      res = trigger_installation( :headers => {"Content-Type"=>"application/json"}, :body => body )
      @id = JSON.parse(res.body).fetch('install').fetch('id').to_i
      self
    end

    def self.trigger!
      new.trigger!
    end

    def wait_for_result
      while JSON.parse(get_installation(id).body).fetch('status') == 'running'
        print ' .'.green
        sleep 10
      end
      puts ''
    end

    private
    def body
      @body ||= {'errands' => errands, 'ignore_warnings' => true }.to_json
    end
    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def errands
      res = { }
      staged_products_guids.each do |product_guid|
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
