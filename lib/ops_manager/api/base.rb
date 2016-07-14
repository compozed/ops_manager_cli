class OpsManager
  module Api
    class Base
      include OpsManager::Logging

      def get(endpoint, opts = {})
        uri = uri_for(endpoint)
        http = http_for(uri)
        request = Net::HTTP::Get.new(uri.request_uri)

        if opts.has_key?(:basic_auth)
          request.basic_auth( opts[:basic_auth][:username], opts[:basic_auth][:password])
        end

        if opts.has_key?(:headers)
          opts.delete(:headers).each_pair do |k,v|
            request[k] = v
          end
        end

        if opts[:write_to]
          begin
            f = open(opts.fetch(:write_to), "wb")
            http.request(request) do |res|
              res.read_body do |segment|
                f.write(segment)
              end
              logger.info("performing get to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
              logger.info("get response body #{res.body}")
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

      def post(endpoint, opts= {})
        uri = uri_for(endpoint)
        http = http_for(uri)
        request = Net::HTTP::Post.new(uri.request_uri)

        request.basic_auth(username, password) if self.respond_to?(:username)

        if opts.has_key?(:headers)
          opts.delete(:headers).each_pair do |k,v|
            request[k] = v
          end
        end


        body = opts[:body] || ''
        request.body= body

        res = http.request(request).tap do |res|
          logger.info("performing post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
          logger.info("post response body #{res.body}")
        end

        if res.code == '302'
          get(res[ 'Location' ], opts)
        else
          res
        end
      end

      def put(endpoint, opts ={})
        uri = uri_for(endpoint)
        http = http_for(uri)
        request = Net::HTTP::Put.new(uri.request_uri)
        request.set_form_data(opts)

        request.basic_auth(username, password) if self.respond_to?(:username)

        if opts.has_key?(:headers)
          opts.delete(:headers).each_pair do |k,v|
            request[k] = v
          end
        end
        # body = opts.fetch( :body )
        http.request(request).tap do |res|
          logger.info("performing put to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
          logger.info("put response body #{res.body}")
        end
      end

      def multipart_post(endpoint, opts = {})
        uri = uri_for(endpoint)
        http = http_for(uri)

        request = Net::HTTP::Post::Multipart.new(uri.request_uri, opts)

        request.basic_auth(username, password) if self.respond_to?(:username)

        if opts.has_key?(:headers)
          opts.delete(:headers).each_pair do |k,v|
            request[k] = v
          end
        end

        http.request(request).tap do |res|
          logger.info("performing multipart_post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
          logger.info("post response body #{res.body}")
        end
      end

      def delete(endpoint, opts = {})
        uri = uri_for(endpoint)
        http = http_for(uri)
        request = Net::HTTP::Delete.new(uri.request_uri)

        request.basic_auth(username, password) if self.respond_to?(:username)

        if opts.has_key?(:headers)
          opts.delete(:headers).each_pair do |k,v|
            request[k] = v
          end
        end
        http.request(request)
      end

      def uri_for(endpoint)
        if endpoint =~/^http/
          URI.parse(endpoint)
        else
          URI.parse("https://#{target}#{endpoint}")
        end
      end

      def http_for(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.read_timeout = 1200
        end
      end
    end
  end
end
