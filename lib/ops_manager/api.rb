require "ops_manager/logging"
require "net/http/post/multipart"

class OpsManager
  module API
    include OpsManager::Logging

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
      multipart_post( "/api/installation_settings",
                     "installation[file]" => yaml)
    end

    def get_installation_settings(opts = {})
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
      puts '====> Download installation assets...'.green
      get("/api/installation_asset_collection",
          write_to: "installation_assets.zip")
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
      get("/api/installation/#{id}")
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
      get('/api/products')
    end

    def get(endpoint, opts = {})
      uri = uri_for(endpoint)
      http = http_for(uri)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(username, password)

      if opts[:write_to]
        begin
          f = open(opts.fetch(:write_to), "wb")
          http.request(request) do |res|
            res.read_body do |segment|
              f.write(segment)
            end
          end
        ensure
          f.close
        end
      else

        http.request(request).tap do |res|
          logger.info("performing get to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
          logger.info("get response body #{res.body}")
        end
      end
    end

    def post(endpoint, opts= {body: ''})
      uri = uri_for(endpoint)
      http = http_for(uri)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(username, password)
      body = opts.fetch(:body)
      request.body= body
      http.request(request).tap do |res|
        logger.info("performing post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
        logger.info("post response body #{res.body}")
      end
    end

    def put(endpoint, opts)
      uri = uri_for(endpoint)
      http = http_for(uri)
      request = Net::HTTP::Put.new(uri.request_uri)
      request.set_form_data( opts)
      request.basic_auth(username, password)
      # body = opts.fetch( :body )
      http.request(request).tap do |res|
        logger.info("performing put to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
        logger.info("put response body #{res.body}")
      end
    end

    def multipart_post(endpoint, opts)
      uri = uri_for(endpoint)
      http = http_for(uri)
      request = Net::HTTP::Post::Multipart.new(uri.request_uri, opts)
      request.basic_auth(username, password)
      http.request(request).tap do |res|
        logger.info("performing multipart_post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
        logger.info("post response body #{res.body}")
      end
    end

    def delete(endpoint, opts = {})
      uri = uri_for(endpoint)
      http = http_for(uri)
      request = Net::HTTP::Delete.new(uri.request_uri)
      request.basic_auth(username, password)
      http.request(request)
    end

    def current_version
      products = JSON.parse(get_products.body)
      directors = products.select{ |i| i.fetch('name') =~/p-bosh|microbosh/ }
      @current_version ||= directors
        .inject([]){ |r, i| r << i.fetch('product_version') }.sort.last
    rescue Errno::ETIMEDOUT , Net::HTTPFatalError, Net::OpenTimeout
      nil
    end
    private

    def http_for(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.read_timeout = 1200
      end
    end

    def uri_for(endpoint)
      URI.parse("https://#{target}#{endpoint}")
    end

    def target
      @target ||= OpsManager.get_conf(:target)
    end

    def username
      @username ||= OpsManager.get_conf(:username)
    end

    def password
      @password ||= OpsManager.get_conf(:password)
    end
  end
end
