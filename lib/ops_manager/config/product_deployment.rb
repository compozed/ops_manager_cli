require 'ops_manager/config/base'

class OpsManager
  module Config
    class ProductDeployment < Base
      def initialize(config)
        super(config)
        validate_presence_of! :name, :desired_version 
        expand_path_for! :stemcell
      end
    end
  end
end
