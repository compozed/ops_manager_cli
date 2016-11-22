require "clamp"
require "ops_manager/product_deployment"
require "ops_manager/appliance_deployment"
require "ops_manager/product_template_generator"
require "ops_manager/director_template_generator"
require "ops_manager/installation"

class OpsManager
  class Cli < Clamp::Command

    class Target < Clamp::Command
      parameter "OPS_MANAGER_IP", "OpsManager url", required: true

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
      parameter "USERNAME", "OpsManager username", required: true
      parameter "PASSWORD", "OpsManager password", required: true

      def execute
        OpsManager.login(@username, @password)
      end
    end

    class DeployAppliance < Clamp::Command
      parameter "OPS_MANAGER_CONFIG", "OpsManager appliance config file", required: true

      def execute
        OpsManager::ApplianceDeployment.new(ops_manager_config).run
      end
    end

    class DeployProduct < Clamp::Command
      parameter "PRODUCT_CONFIG", "OpsManager product config file", required: true
      option "--force", :flag, "force deployment"

      def execute
        OpsManager::ProductDeployment.new(product_config, force?).run
      end
    end

    class GetInstallationSettings < Clamp::Command
      def execute
        puts parsed_response.to_yaml
      end

      private
      def parsed_response
        response = opsman.get_installation_settings
        JSON.parse(response.body)
      end

      def opsman
        OpsManager::Api::Opsman.new(silent: true)
      end
    end

    class ImportStemcell < Clamp::Command
      parameter "STEMCELL_FILEPATH", "Stemcell file path", required: true

      def execute
        OpsManager::Api::Opsman.new.import_stemcell(@stemcell_filepath)
      end
    end

    class DeleteUnusedProducts < Clamp::Command

      def execute
        OpsManager::Api::Opsman.new.delete_products
      end
    end

    class GetProductTemplate < Clamp::Command
      parameter "PRODUCT_NAME", "Product tile name. Example: p-cf", required: true

      def execute
        puts OpsManager::ProductTemplateGenerator.new(@product_name).generate_yml
      end
    end

    class GetInstallationLogs < Clamp::Command
      parameter "INSTALLATION_ID", "Installation ID. Use 'last' to retrive the latest", required: true

      def execute
        if @installation_id == "last"
          puts OpsManager::Installation.all.last.logs
        else
          puts OpsManager::Installation.new(@installation_id.to_i).logs
        end
      end
    end

    class GetDirectorTemplate < Clamp::Command
      def execute
        puts OpsManager::DirectorTemplateGenerator.new.generate_yml
      end
    end

    class Curl < Clamp::Command
      option ['-X', '--http-method'], "HTTP_METHOD", "HTTP Method (GET,POST)", default: 'GET'
      option ['-d', '--data'], "HTTP_POST_DATA", "HTTP Post Data(POST, PUT)", default: ''
      parameter "ENDPOINT", "OpsManager api endpoint. eg: /api/v0/installation_settings", required: true

      def execute
        puts case http_method.strip
        when 'GET'
          opsman.authenticated_get(@endpoint).body
        when 'POST'
          opsman.authenticated_post(@endpoint).body
        when 'PUT'
          opsman.authenticated_put(@endpoint, body: strip(@data, "'")).body
        else
          "Unsupported method: #{http_method.strip}"
        end
      end

      private
      def opsman
        OpsManager::Api::Opsman.new(silent: true)
      end

      def strip(string, chars)
        chars = Regexp.escape(chars)
        string.strip.gsub(/\A[#{chars}]+|[#{chars}]+\z/, "")
      end
    end

    class Version < Clamp::Command
      def execute
        puts OpsManager::VERSION
      end
    end

    # Core commands
    subcommand "status", "Test credentials and shows status", Status
    subcommand "target", "Target an OpsManager appliance", Target
    subcommand "login", "Login to OpsManager" , Login
    subcommand "deploy-appliance", "Deploys/Upgrades OpsManager", DeployAppliance
    subcommand "deploy-product", "Deploys/Upgrades product tiles", DeployProduct
    subcommand "get-director-template", "Generates Director installation template", GetDirectorTemplate
    subcommand "get-product-template", "Generates Product tile installation template", GetProductTemplate

    # Other commands
    subcommand "version", "Shows OpsManagerCLI version", Version
    subcommand "curl", "Authenticated curl requests(POST/GET)", Curl
    subcommand "delete-unused-products", "Deletes unused product tiles", DeleteUnusedProducts
    subcommand "get-installation-settings", "Gets installation settings", GetInstallationSettings
    subcommand "get-installation-logs", "Gets installation logs", GetInstallationLogs
    subcommand "import-stemcell", "Uploads stemcell to OpsManager", ImportStemcell

  end
end
