require "clamp"
require "ops_manager/product"

class OpsManager
  class Cli < Clamp::Command

    class Target < Clamp::Command
      parameter "OPS_MANAGER_IP", "Ops Manager Ip", required: true

      def execute
        OpsManager.target(@ops_manager_ip)
      end
    end

    class Login < Clamp::Command
      parameter "USERNAME", "opsManager username", required: true
      parameter "PASSWORD", "opsManager password", required: true

      def execute
        OpsManager.login(@username, @password)
      end
    end

    class Deploy < Clamp::Command
      parameter "OPS_MANAGER_CONFIG", "opsManager config file", required: true

      def execute
        OpsManager.new.deploy(@ops_manager_config)
      end
    end

    class DeployProduct < Clamp::Command
      parameter "PRODUCT_CONFIG", "opsManager product config file", required: true
      option "--force", :flag, "force deployment" 

      def execute
        OpsManager.new.deploy_product(@product_config, force?)
      end
    end

    subcommand "target", "target an ops_manager deployment" , Target
    subcommand "login", "login against ops_manager" , Login
    subcommand "deploy", "deploys or upgrades ops_manager" , Deploy
    subcommand "deploy-product", "deploys product tiles" , DeployProduct
  end
end
