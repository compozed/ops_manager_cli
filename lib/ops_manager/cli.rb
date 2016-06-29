require "clamp"
require "ops_manager/product_deployment"
require "ops_manager/deployment"
require "ops_manager/product_template_generator"
require "ops_manager/director_template_generator"
require "ops_manager/installation"

class OpsManager
  class Cli < Clamp::Command

    class Target < Clamp::Command
      parameter "OPS_MANAGER_IP", "Ops Manager Ip", required: true

      def execute
        OpsManager.set_target(@ops_manager_ip)
      end
    end

    class Status < Clamp::Command
      def execute
        puts OpsManager.show_status
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
      def execute
        OpsManager::Deployment.new.run
      end
    end

    class Deployment < Clamp::Command
      parameter "OPS_MANAGER_CONFIG", "opsManager config file", required: true

      def execute
        OpsManager.deployment=@ops_manager_config
      end
    end

    class DeployProduct < Clamp::Command
      parameter "PRODUCT_CONFIG", "opsManager product config file", required: true
      option "--force", :flag, "force deployment"

      def execute
        OpsManager::ProductDeployment.new(product_config, force?).run
      end
    end

    class GetInstallationSettings < Clamp::Command
      parameter "DESTINATION", "where should it place the donwloaded settings", required: true

      def execute
        OpsManager::Api::Opsman.new.get_installation_settings(write_to: @destination)
      end
    end

    class ImportStemcell < Clamp::Command
      parameter "STEMCELL_FILEPATH", "Stemcell filepath", required: true

      def execute
        OpsManager.new.import_stemcell(@stemcell_filepath)
      end
    end

    class DeleteUnusedProducts < Clamp::Command

      def execute
        OpsManager.new.delete_products
      end
    end

    class GetUaaToken < Clamp::Command
      def execute
        puts OpsManager::Api::Opsman.new.get_token.info.fetch('access_token')
      end
    end

    class SSH < Clamp::Command
      def execute
        `ssh ubuntu@#{OpsManager.get_conf(:target)}`
      end
    end

    class GetProductTemplate < Clamp::Command
      parameter "PRODUCT_NAME", "Product Name", required: true

      def execute
        puts OpsManager::ProductTemplateGenerator.new(@product_name).generate_yml
      end
    end

    class GetInstallationLogs < Clamp::Command
      parameter "INSTALLATION_ID", "Installation ID", required: true

      def execute
        if @installation_id == "last"
          puts OpsManager::Installation.all.last.logs
        else
          puts OpsManager::Installation.new(@installation_id).logs
        end
      end
    end

    class GetDirectorTemplate < Clamp::Command
      def execute
        puts OpsManager::DirectorTemplateGenerator.new.generate_yml
      end
    end
    subcommand "target", "target an ops_manager deployment" , Target
    subcommand "login", "login against ops_manager" , Login
    subcommand "ssh", "ssh into ops_manager machine" , SSH
    subcommand "deploy", "deploys or upgrades ops_manager" , Deploy
    subcommand "deployment", "sets deployment config file path" , Deployment
    subcommand "deploy-product", "deploys product tiles" , DeployProduct
    subcommand "get-installation-settings", "pulls installation settings" , GetInstallationSettings
    subcommand "get-product-template", "pulls product installation template" , GetProductTemplate
    subcommand "get-director-template", "pulls director installation template" , GetDirectorTemplate
    subcommand "import-stemcell", "Uploads stemcell to Ops Manager" , ImportStemcell
    subcommand "delete-unused-products", "Deletes unused products" , DeleteUnusedProducts
    subcommand "get-uaa-token", "get uaa token from ops manager" , GetUaaToken
    subcommand "get-installation-logs", "get installation log" , GetInstallationLogs
  end
end
