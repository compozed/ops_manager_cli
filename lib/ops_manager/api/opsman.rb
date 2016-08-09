require "ops_manager/logging"
require "ops_manager/api/base"
require "net/http/post/multipart"
require "uaa"

class OpsManager
  module Api
    class Opsman < OpsManager::Api::Base
      attr_reader :silent

      def initialize(opts = {})
        @silent = opts[:silent]
      end

      def say_green(str)
        puts str.green unless silent
      end

      def print_green(str)
        print str.green unless silent
      end

      def create_user
        body= "setup[decryption_passphrase]=#{password}&setup[decryption_passphrase_confirmation]=#{password}&setup[eula_accepted]=true&setup[identity_provider]=internal&setup[admin_user_name]=#{username}&setup[admin_password]=#{password}&setup[admin_password_confirmation]=#{password}"
        post("/api/v0/setup" , body: body)
      end

      def upload_installation_settings(filepath = 'installation_settings.json')
        say_green( '====> Uploading installation settings...')
        yaml = UploadIO.new(filepath, 'text/yaml')
        opts = { "installation[file]" => yaml}
        res = authenticated_multipart_post("/api/installation_settings", opts)
        raise OpsManager::InstallationSettingsError.new(res.body) unless res.code == '200'
        res
      end

      def get_staged_products(opts = {})
        authenticated_get("/api/v0/staged/products", opts)
      end

      def get_installation_settings(opts = {})
        say_green( '====> Downloading installation settings...')
        authenticated_get("/api/installation_settings", opts)
      end

      def upload_installation_assets
        say_green( '====> Uploading installation assets...')
        zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
        opts = {:passphrase => @password, "installation[file]" => zip }
        multipart_post( "/api/v0/installation_asset_collection", opts)
      end

      def get_installation_assets
        opts = { write_to: "installation_assets.zip" }
        say_green( '====> Download installation assets...')
        authenticated_get("/api/v0/installation_asset_collection", opts)
      end

      def delete_products(opts = {})
        say_green( '====> Deleating unused products...')
        opts = add_authentication(opts)
        delete('/api/v0/products', opts)
      end

      def trigger_installation(opts = {})
        print_green('====> Applying changes...')
        authenticated_post('/api/v0/installations', opts)
      end

      def add_staged_products(name, version)
        print_green( "====> Adding available product to the installation...")
        body = "name=#{name}&product_version=#{version}"
        res = authenticated_post('/api/v0/staged/products', body: body)
        raise OpsManager::ProductDeploymentError.new(res.body) if res.code == '404'
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
        authenticated_get('/api/v0/installations')
      end

      def upgrade_product_installation(guid, product_version)
        say_green( "====> Bumping product installation #{guid} product_version to #{product_version}...")
        opts = { to_version: product_version }
        opts = add_authentication(opts)
        res = put("/api/v0/staged/products/#{guid}", opts)
        raise OpsManager::UpgradeError.new(res.body) unless res.code == '200'
        res
      end

      def upload_product(filepath)
        file = "#{filepath}"
        cmd = "curl -k \"https://#{target}/api/v0/available_products\" -F 'product[file]=@#{file}' -X POST -H 'Authorization: Bearer #{access_token}'"
        logger.info "running cmd: #{cmd}"
        body = `#{cmd}`
        logger.info "Upload product response: #{body}"
        raise OpsManager::ProductUploadError if body.include? "error"
      end

      def get_available_products
        authenticated_get("/api/v0/available_products")
      end

      def get_current_version
        products = JSON.parse(get_available_products.body)
        directors = products.select{ |i| i.fetch('name') =~/p-bosh|microbosh/ }
        versions = directors.inject([]){ |r, i| r << OpsManager::Semver.new(i.fetch('product_version')) }
        versions.sort.last.to_s.gsub(/.0$/,'')

      rescue Errno::ETIMEDOUT , Errno::EHOSTUNREACH, Net::HTTPFatalError, Net::OpenTimeout
        nil
      end


      def import_stemcell(filepath)
        return unless filepath
        say_green('====> Uploading stemcell...')
        tar = UploadIO.new(filepath, 'multipart/form-data')
        opts = { "stemcell[file]" => tar }
        res = authenticated_multipart_post("/api/v0/stemcells", opts)
        raise OpsManager::StemcellUploadError.new(res.body) unless res.code == '200'
        res
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

      def get_token
        token_issuer.owner_password_grant('admin', password, 'opsman.admin').tap do |token|
          logger.info "UAA Token: #{token.inspect}"
        end
      rescue  CF::UAA::TargetError
        nil
      end

      def authenticated_get(endpoint, opts = {})
        get(endpoint, add_authentication(opts))
      end

      def authenticated_post(endpoint, opts = {})
        post(endpoint, add_authentication(opts))
      end

      def authenticated_multipart_post(endpoint, opts = {})
        multipart_post(endpoint, add_authentication(opts))
      end

      private
      def token_issuer
        @token_issuer ||= CF::UAA::TokenIssuer.new(
          "https://#{target}/uaa", 'opsman', nil, skip_ssl_validation: true )
      end

      def access_token
        @access_token ||= get_token.info['access_token']
      end


      def add_authentication(opts={})
        opts[:headers] ||= {}
        opts[:headers]['Authorization'] ||= "Bearer #{access_token}"
        opts
      end
    end
  end
end
