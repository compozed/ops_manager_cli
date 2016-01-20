require 'byebug'
require "ops_manager/logging"
require "net/http/post/multipart"
require "rest-client"

class OpsManager
  class API
    include OpsManager::Logging
    attr_reader :target, :username, :password

    def initialize(target, username, password)
      @target, @username, @password = target, username, password
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

    def post(endpoint, opts)
      uri = uri_for(endpoint)
      http = http_for(uri)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(username, password)
      body = opts.fetch( :body )
      request.body= body
      http.request(request).tap do |res|
        logger.info("performing post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
        logger.info("post response body #{res.body}")
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

  end
end
