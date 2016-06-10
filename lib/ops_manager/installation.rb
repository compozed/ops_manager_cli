class OpsManager
  class Installation
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def logs
      parsed_logs.fetch('logs')
    end

    class << self
      def all
        parsed_installations.fetch('installations').collect{ |i| new(i.fetch('id')) }.reverse
      end

      private

      def parsed_installations
        JSON.parse(opsman_api.get_installations.body)
      end

      def opsman_api
        OpsManager::Api::Opsman.new
      end
    end

    private
    def parsed_logs
      JSON.parse(opsman_api.get_installation_logs(id).body)
    end

    def opsman_api
      @opsman_api ||= OpsManager::Api::Opsman.new
    end
  end
end
