class OpsManager
  class Installation
    extend Forwardable
    def_delegators :opsman_api, :trigger_installation, :get_installation, :get_current_version
    attr_reader :id

    def self.trigger!
      new
    end

    def initialize
      res = trigger_installation
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
  end
end
