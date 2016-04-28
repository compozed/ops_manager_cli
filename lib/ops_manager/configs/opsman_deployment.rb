require 'ops_manager/configs/Base'

class OpsManager
  class Configs
    class OpsmanDeployment < Base
      def initialize(config)
        super(config)
        validate_presence_of!(:name, :version, :provider, :username, :password, :pivnet_token, :ip, :opts)
      end
    end
  end
end
