require "ops_manager/logging"
require "net/http/post/multipart"

class OpsManager::Deployment
  include OpsManager::Logging
  attr_accessor :name, :ip, :username, :password, :opts

  def initialize(name, ip, username, password)
    @name, @ip, @username, @password = name, ip, username, password
  end
  %w{ deploy downgrade upgrade }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end


  def current_version
    @current_version ||= current_products.select{ |i| i.fetch('name') == 'microbosh' }
      .inject([]){ |r, i| r << i.fetch('product_version') }.sort.last
  rescue Errno::ETIMEDOUT
    nil
  end

  def create_user
    if new_version =~/1.5/
      body= "user[user_name]=#{@username}&user[password]=#{@password}&user[password_confirmantion]=#{@password}"
      uri= "/api/users"
    elsif new_version=~/1.6/
      body= "setup[user_name]=#{@username}&setup[password]=#{@password}&setup[password_confirmantion]=#{@password}&setup[eula_accepted]=true"
      uri= "/api/setup"
    end

    res = post(uri, body: body)
    res
  end

  private
  def current_products
    @current_products ||= JSON.parse(get("/api/products").body)
    return @current_products
  end

  def current_vm_name
    @current_vm_name ||= "#{@name}-#{current_version}"
  end

  def get(endpoint, opts = {})
    uri =  URI.parse("https://#{@ip}#{endpoint}")
    http = http_for(uri)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@username, @password)

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
      uri =  URI.parse("https://#{@ip}#{endpoint}")
      http = http_for(uri)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(@username, @password)
      body = opts.fetch( :body )
      request.body= body
      http.request(request).tap do |res|
        logger.info("performing post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
        logger.info("post response body #{res.body}")
      end
  end

  def multipart_post(endpoint, opts)
    uri = URI.parse("https://#{@ip}#{endpoint}")
    http = http_for(uri)
    request = Net::HTTP::Post::Multipart.new(uri.request_uri, opts)
    request.basic_auth(@username, @password)
    http.request(request).tap do |res|
      logger.info("performing multipart_post to #{uri} with opts: #{opts.inspect}  res.code: #{res.code}")
      logger.info("post response body #{res.body}")
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
