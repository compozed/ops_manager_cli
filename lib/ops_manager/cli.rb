require "clamp"
require "ops_manager/product"

class OpsManager
  class Cli < Clamp::Command

    class Target < Clamp::Command
      parameter "OPS_MANAGER_IP", "opsManager cloud config file", required: true

      def execute
        OpsManager.target(@ops_manager_ip)
      end
    end

    class Login < Clamp::Command
      parameter "USERNAME", "opsManager user name", required: true
      parameter "PASSWORD", "opsManager user password", required: true

      def execute
        OpsManager.login(@username, @password)
      end
    end

    class Deploy < Clamp::Command
      parameter "OPS_MANAGER_CONFIG", "opsManager cloud config file", required: true
      def execute
        OpsManager.new(@ops_manager_config).deploy
      end
    end

    class DeployProduct < Clamp::Command
      parameter "PRODUCT_CONFIG", "opsManager product config file", required: true

      def execute
        OpsManager::Product.new(@product_config).deploy
      end
    end

    subcommand "target", "target ops_manager" , Target
    subcommand "login", "target ops_manager" , Login
    subcommand "deploy", "deploy ops_manager" , Deploy
    subcommand "deploy-product", "deploys product tiles" , DeployProduct
  end
end
