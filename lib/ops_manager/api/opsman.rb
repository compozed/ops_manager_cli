require "ops_manager/logging"
require "ops_manager/api/base"
require "net/http/post/multipart"

class OpsManager
  module Api
    class Opsman
      include OpsManager::Api::Base

      def create_user(version)
        if version =~/1.5/
          body= "user[user_name]=#{username}&user[password]=#{password}&user[password_confirmantion]=#{password}"
          uri= "/api/users"
        elsif version=~/1.6/
          body= "setup[user_name]=#{username}&setup[password]=#{password}&setup[password_confirmantion]=#{password}&setup[eula_accepted]=true"
          uri= "/api/setup"
        end

        post(uri, body: body)
      end

      def upload_installation_settings(filepath)
        puts '====> Uploading installation settings...'.green
        yaml = UploadIO.new(filepath, 'text/yaml')
        res = multipart_post( "/api/installation_settings",
                             "installation[file]" => yaml)
        raise OpsManager::InstallationSettingsError.new(res.body) unless res.code == '200'
        res
      end

      def get_installation_settings(opts = {})
        puts '====> Downloading installation settings...'.green
        opts.merge!( { basic_auth: { username: username, password: password } } )
        get("/api/installation_settings", opts)
      end

      def upload_installation_assets
        puts '====> Uploading installation assets...'.green
        zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
        multipart_post( "/api/installation_asset_collection",
                       :password => @password,
                       "installation[file]" => zip
                      )
      end

      def get_installation_assets
        opts = { write_to: "installation_assets.zip" }
        opts.merge!( basic_auth: { username: username, password: password })

        puts '====> Download installation assets...'.green
        get("/api/installation_asset_collection", opts)
      end

      def delete_products
        puts '====> Deleating unused products...'.green
        delete('/api/products')
      end

      def trigger_installation
        puts '====> Applying changes...'.green
        post('/api/installation')
      end

      def get_installation(id)
        opts = { basic_auth: { username: username, password: password }}
        res = get("/api/installation/#{id}" , opts )
        raise OpsManager::InstallationError.new(res.body) if res.body =~  /failed/
        res
      end

      def upgrade_product_installation(guid, version)
        puts "====> Bumping product installation #{guid} version to #{version}...".green
        res = put("/api/installation_settings/products/#{guid}", to_version: version)
        raise OpsManager::UpgradeError.new(res.body) unless res.code == '200'
        res
      end

      def upload_product(filepath)
        file = "#{filepath}"
        cmd = "curl -k \"https://#{target}/api/products\" -F 'product[file]=@#{file}' -X POST -u #{username}:#{password}"
        logger.info "running cmd: #{cmd}"
        puts `#{cmd}`
      end

      def get_products
        get('/api/products', { basic_auth: { username: username, password: password }} )
      end

      def current_version
        products = JSON.parse(get_products.body)
        directors = products.select{ |i| i.fetch('name') =~/p-bosh|microbosh/ }
        versions = directors.inject([]){ |r, i| r << OpsManager::Version.new(i.fetch('product_version')) }
        @current_version ||= versions.sort.last.to_s
      rescue Errno::ETIMEDOUT , Errno::EHOSTUNREACH, Net::HTTPFatalError, Net::OpenTimeout
        nil
      end

      def import_stemcell(filepath)
        return unless filepath
        puts '====> Uploading stemcell...'.green
        tar = UploadIO.new(filepath, 'multipart/form-data')
        multipart_post( "/api/stemcells",
                       "stemcell[file]" => tar
                      )
      end

      def username
        @username ||= OpsManager.get_conf(:username)
      end

      def password
        @password ||= OpsManager.get_conf(:password)
      end

      private

      def target
        @target ||= OpsManager.get_conf(:target)
      end

    end
  end
end
