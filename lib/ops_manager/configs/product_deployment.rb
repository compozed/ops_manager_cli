require 'ops_manager/configs/base'

class OpsManager
  class Configs
    class ProductDeployment < Base
      def initialize(config)
        super(config)
        validate_presence_of!(:name, :desired_version)
      end

      def stemcell
        find_full_path(@config['stemcell'])
      end
    end
  end
end
