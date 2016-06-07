class OpsManager
  class Installation
    extend Forwardable
    def_delegators :opsman_api, :trigger_installation, :get_installation, :get_current_version, :get_staged_products
    attr_reader :id

    def self.trigger!
      new
    end

    def initialize
      body = [ 'ignore_warnings=true' ]
      body << staged_products_guids.collect{ |guid| "enabled_errands[#{guid}]{}" }
      res = trigger_installation( body: body.join('&') )
      @id = JSON.parse(res.body).fetch('install').fetch('id').to_i
    end

    def wait_for_result
      while JSON.parse(get_installation(id).body).fetch('status') == 'running'
        print '.'.green
        sleep 10
      end
    end

    private
    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def staged_products_guids
      JSON.parse(get_staged_products.body).collect{ |product| product.fetch('guid') }
    end
  end
end
