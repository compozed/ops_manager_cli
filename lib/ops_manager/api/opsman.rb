require "ops_manager/logging"
require "ops_manager/api/base"
require "net/http/post/multipart"

class OpsManager
  module Api
    class Opsman < OpsManager::Api::Base
      attr_accessor :ops_manager_version

      def initialize(ops_manager_version = nil)
        @ops_manager_version = ops_manager_version
      end


      def create_user
        case ops_manager_version
        when /1.5/
          body= "user[user_name]=#{username}&user[password]=#{password}&user[password_confirmantion]=#{password}"
          uri= "/users"
        when /1.6/
          body= "setup[user_name]=#{username}&setup[password]=#{password}&setup[password_confirmantion]=#{password}&setup[eula_accepted]=true"
          uri= "/setup"
        when /1.7/
          body= "setup[decryption_passphrase]=passphrase&setup[decryption_passphrase_confirmation]=passphrase&setup[eula_accepted]=true&setup[identity_provider]=internal&setup[admin_user_name]=#{username}&setup[admin_password]=#{password}&setup[admin_password_confirmation]=#{password}"
          uri= "/setup"
        end

        post(uri, body: body)
      end

      def upload_installation_settings(filepath)
        puts '====> Uploading installation settings...'.green
        yaml = UploadIO.new(filepath, 'text/yaml')
        res = multipart_post( "/installation_settings",
                             "installation[file]" => yaml)
        raise OpsManager::InstallationSettingsError.new(res.body) unless res.code == '200'
        res
      end

      def get_installation_settings(opts = {})
        puts '====> Downloading installation settings...'.green
        opts.merge!( { basic_auth: { username: username, password: password } } )
        get("/installation_settings", opts)
      end

      def upload_installation_assets
        puts '====> Uploading installation assets...'.green
        zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
        multipart_post( "/installation_asset_collection",
                       :password => @password,
                       "installation[file]" => zip
                      )
      end

      def get_installation_assets
        opts = { write_to: "installation_assets.zip" }
        opts.merge!( basic_auth: { username: username, password: password })

        puts '====> Download installation assets...'.green
        get("/installation_asset_collection", opts)
      end

      def delete_products
        puts '====> Deleating unused products...'.green
        delete('/products')
      end

      def trigger_installation
        puts '====> Applying changes...'.green
        post('/installation')
      end

      def get_installation(id)
        opts = { basic_auth: { username: username, password: password }}
        res = get("/installation/#{id}" , opts )
        raise OpsManager::InstallationError.new(res.body) if res.body =~  /failed/
        res
      end

      def upgrade_product_installation(guid, product_version)
        puts "====> Bumping product installation #{guid} product_version to #{product_version}...".green
        res = put("/installation_settings/products/#{guid}", to_version: product_version)
        raise OpsManager::UpgradeError.new(res.body) unless res.code == '200'
        res
      end

      def upload_product(filepath)
        file = "#{filepath}"
        cmd = "curl -k \"https://#{target}/products\" -F 'product[file]=@#{file}' -X POST -u #{username}:#{password}"
        logger.info "running cmd: #{cmd}"
        puts `#{cmd}`
      end

      def get_products
        get('/products', { basic_auth: { username: username, password: password }} )
      end

      def get_current_version
        products = JSON.parse(get_products.body)
        directors = products.select{ |i| i.fetch('name') =~/p-bosh|microbosh/ }
        versions = directors.inject([]){ |r, i| r << OpsManager::Semver.new(i.fetch('product_version')) }
        versions.sort.last.to_s
      rescue Errno::ETIMEDOUT , Errno::EHOSTUNREACH, Net::HTTPFatalError, Net::OpenTimeout
        nil
      end

      def import_stemcell(filepath)
        return unless filepath
        puts '====> Uploading stemcell...'.green
        tar = UploadIO.new(filepath, 'multipart/form-data')
        res = multipart_post( "/stemcells",
                             "stemcell[file]" => tar
                            )

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

      def uri_for(endpoint)
        super("#{api_namespace}#{endpoint}")
      end

      private
      def api_namespace
        case ops_manager_version
        when /1.5/
          "/api"
        when /1.6/
          "/api"
        when /1.7/
          "/api/v0"
        else
          "/api"
        end
      end
    end
  end
end
