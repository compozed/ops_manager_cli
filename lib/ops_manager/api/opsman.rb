require "ops_manager/logging"
require "ops_manager/api/base"
require "net/http/post/multipart"
require "uaa"

class OpsManager
  module Api
    class Opsman < OpsManager::Api::Base
      def create_user
        body= "setup[decryption_passphrase]=#{password}&setup[decryption_passphrase_confirmation]=#{password}&setup[eula_accepted]=true&setup[identity_provider]=internal&setup[admin_user_name]=#{username}&setup[admin_password]=#{password}&setup[admin_password_confirmation]=#{password}"
        post("/api/v0/setup" , body: body)
      end

      def upload_installation_settings(filepath = 'installation_settings.json')
        print_green '====> Uploading installation settings ...'
        yaml = UploadIO.new(filepath, 'text/yaml')
        opts = { "installation[file]" => yaml}
        res = authenticated_multipart_post("/api/installation_settings", opts)
        raise OpsManager::InstallationSettingsError.new(res.body) unless res.code == '200'
        say_green 'done'
        res
      end

      def get_staged_products(opts = {})
        authenticated_get("/api/v0/staged/products", opts)
      end

      def get_installation_settings(opts = {})
        print_green '====> Downloading installation settings ...'
        res = authenticated_get("/api/installation_settings", opts)
        say_green 'done'
        res
      end

      def upload_installation_assets
        print_green( '====> Uploading installation assets ...')
        zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
        opts = {:passphrase => @password, "installation[file]" => zip }
        res = multipart_post( "/api/v0/installation_asset_collection", opts)
        say_green 'done'
        res
      end

      def get_installation_assets
        opts = { write_to: "installation_assets.zip" }
        say_green '====> Download installation assets ...'
        res = authenticated_get("/api/v0/installation_asset_collection", opts)
        say_green 'done'
        res
      end

      def delete_products(opts = {})
        print_green '====> Deleating unused products ...'
        res = authenticated_delete('/api/v0/products', opts)
        say_green 'done'
        res
      end

      def trigger_installation(opts = {})
        print_green('====> Applying changes')
        res = authenticated_post('/api/v0/installations', opts)
        raise OpsManager::InstallationError.new(res.body) if res.code =~  /422/
        res
      end

      def add_staged_products(name, version)
        print_green( "====> Adding available product to the installation ...")
        body = "name=#{name}&product_version=#{version}"
        res = authenticated_post('/api/v0/staged/products', body: body)
        raise OpsManager::ProductDeploymentError.new(res.body) if res.code =~ /404|500/
        say_green('done')
        res
      end

      def get_installation(id)
        res = authenticated_get("/api/v0/installations/#{id}")
        raise OpsManager::InstallationError.new(res.body) if res.body =~  /failed/
        res
      end

      def get_installation_logs(id)
        authenticated_get("/api/v0/installations/#{id}/logs")
      end

      def get_staged_products_errands(product_guid)
        authenticated_get("/api/v0/staged/products/#{product_guid}/errands" )
      end

      def get_installations(opts = {})
        print_green '====> Getting installations ...'
        res = authenticated_get('/api/v0/installations')
        say_green 'done'
        res
      end

      def upgrade_product_installation(guid, product_version)
        print_green "====> Bumping product installation #{guid} product_version to #{product_version} ..."
        opts = { :body => { 'to_version' => product_version }.to_json }
        res = authenticated_put("/api/v0/staged/products/#{guid}", opts)
        raise OpsManager::UpgradeError.new(res.body) unless res.code == '200'
        say_green 'done'
        res
      end

      def upload_product(filepath)
        file = "#{filepath}"
        cmd = "curl -s -k \"https://#{target}/api/v0/available_products\" -F 'product[file]=@#{file}' -X POST -H 'Authorization: Bearer #{access_token}'"
        logger.info "running cmd: #{cmd}"
        body = `#{cmd}`
        logger.info "Upload product response: #{body}"
        raise OpsManager::ProductUploadError if body.include? "error"
      end

      def get_available_products
        authenticated_get("/api/v0/available_products")
      end

      def get_diagnostic_report
        authenticated_get("/api/v0/diagnostic_report")
      rescue Errno::ETIMEDOUT , Errno::EHOSTUNREACH, Net::HTTPFatalError, Net::OpenTimeout
        nil
      end

      def import_stemcell(filepath)
        return unless filepath
        tar = UploadIO.new(filepath, 'multipart/form-data')
        print_green "====> Uploading stemcell: #{filepath} ..."
        opts = { "stemcell[file]" => tar }
        res = nil

        3.times do
          res = authenticated_multipart_post("/api/v0/stemcells", opts)
          case res.code
            when '200' ; break
            when '503' ; sleep(60)
          end
        end

        raise OpsManager::StemcellUploadError.new(res.body) unless res.code == '200'
        say_green 'done'
        res
      end

      def get_token
        token_issuer.owner_password_grant(username, password, 'opsman.admin').tap do |token|
          logger.info "UAA Token: #{token.inspect}"
        end
      rescue  CF::UAA::TargetError
        nil
      end

      def username
        @username ||= OpsManager.get_conf(:username)
      end

      def password
        @password ||= OpsManager.get_conf(:password)
      end

      def target
        @target ||= OpsManager.get_conf(:target)
      end


      def reset_access_token
        @access_token = nil
      end

      def access_token
        @access_token ||= get_token.info['access_token']
      end

      private
      def token_issuer
        @token_issuer ||= CF::UAA::TokenIssuer.new(
          "https://#{target}/uaa", 'opsman', nil, skip_ssl_validation: true )
      end

      def authorization_header
        "Bearer #{access_token}"
      end
    end
  end
end
