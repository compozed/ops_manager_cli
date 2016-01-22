require 'ops_manager/api'

class OpsManager
  class Installation
    attr_reader :id

    include OpsManager::API

    def trigger!
      res = trigger_installation
      @id = JSON.parse(res.body).fetch('install').fetch('id')
    end

    def status
      if id
        res = get_installation(id)
        JSON.parse(res.body).fetch('status')
      end
    end
  end
end
