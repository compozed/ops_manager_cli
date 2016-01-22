require 'byebug'
require "ops_manager/logging"
require "net/http/post/multipart"
require "rest-client"

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

    res = post(uri, body: body)
    res
  end

    def delete_products
      delete('/api/products')
    end

    def trigger_installation
      post('/api/installation')
    end

    def get_installation(id)
      get("/api/installation/#{id}")
    end

    def upgrade_product_installation(guid, version)
      put("/api/installation_settings/products/#{guid}", to_version: version)
    end

    def upload_product(filepath)
      file = "#{Dir.pwd}/#{filepath}"
      cmd = "curl -k \"https://#{target}/api/products\" -F 'product[file]=@#{file}' -X POST -u #{username}:#{password}"
      logger.info "running cmd: #{cmd}"
      puts `#{cmd}`
    end

    def get_products
      JSON.parse( get('/api/products').body )
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
        http.request(request)
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
