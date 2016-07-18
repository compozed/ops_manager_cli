class OpsManager
  class InstallationRunner
    extend Forwardable
    def_delegators :opsman_api, :trigger_installation, :get_installation, :get_current_version, :get_staged_products
    attr_reader :id

    def trigger!
      res = trigger_installation( body: body.join('&') )
      @id = JSON.parse(res.body).fetch('install').fetch('id').to_i
      self
    end

    def self.trigger!
      new.trigger!
    end

    def initialize
      body << staged_products_guids.collect{ |guid| "enabled_errands[#{guid}]{}" }
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
    end
    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end

    def staged_products_guids
      JSON.parse(get_staged_products.body).collect{ |product| product.fetch('guid') }
    end
  end
end
