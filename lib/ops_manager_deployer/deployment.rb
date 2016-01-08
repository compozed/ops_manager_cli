require "ops_manager_deployer/logging"
class OpsManagerDeployer::Deployment
  include OpsManagerDeployer::Logging
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
    logger.info("performing post to #{uri} with body: #{body} res: #{res}")
    res
  end

  private
  def current_products
    @current_products ||= JSON.parse(get("/api/products").body)
    logger.info "products found: #{@current_products}"
    return @current_products
  end

  def current_vm_name
    @current_vm_name ||= "#{@name}-#{current_version}"
  end

  def get(uri)
    http_request(uri, :get)
  end

  def post(uri, opts)
    http_request(uri, :post, opts)
  end

  def http_request(uri, method, opts=nil)
    uri = URI.parse("https://#{@ip}#{uri}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    case method
    when :get
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(@username, @password)
    when :post
      request = Net::HTTP::Post.new(uri.request_uri )
      request.basic_auth(@username, @password)
      body = opts.fetch( :body )
      request.body= body
      logger.info "Post to #{uri} with body #{ body }"
    end

    http.request(request)
  end
end
