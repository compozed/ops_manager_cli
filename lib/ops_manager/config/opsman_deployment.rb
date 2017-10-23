require 'ops_manager/config/base'

class OpsManager
  module Config
    class OpsmanDeployment < Base
      def initialize(config)
        super(config)
        validate_presence_of! :name, :desired_version, :provider, :username, :password, :pivnet_token, :ip, :opts 
        expand_path_for! :ova_path
      end
    end
  end
end
