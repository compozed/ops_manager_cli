require "ops_manager/logging"
require "net/http/post/multipart"

class OpsManager::Deployment
  include OpsManager::Logging
  attr_accessor :name, :version, :username, :password, :ip

  def initialize(name,  version)
    @name, @version = name, version
    @username = OpsManager.get_conf(:username)
    @password = OpsManager.get_conf(:password)
    @ip = OpsManager.get_conf(:target)
  end

  %w{ stop_current_vm deploy_vm }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end

  def deploy
    deploy_vm
    create_first_user
  end

  def create_first_user
    puts '====> Creating initial user...'.green
    until( create_user.code.to_i == 200) do
      print '.'.green ; sleep 1
    end
  end

  def upgrade
    get_installation_assets
    get_installation_settings
    stop_current_vm
    deploy
    upload_installation_assets
    puts "====> Finish!".green
  end


  def get_installation_assets
    puts '====> Download installation assets...'.green
    get("/api/installation_asset_collection",
       write_to: "installation_assets.zip")
  end

  def upload_installation_assets
    puts '====> Uploading installation assets...'.green
    zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
    multipart_post( "/api/installation_asset_collection",
      :password => @password,
      "installation[file]" => zip
    )
  end

  def get_installation_settings
    puts '====> Downloading installation settings...'.green
    get("/api/installation_settings",
       write_to: "installation_settings.json")
  end

  def current_version
    @current_version ||= current_products.select{ |i| i.fetch('name') == 'microbosh' }
      .inject([]){ |r, i| r << i.fetch('product_version') }.sort.last
  rescue Errno::ETIMEDOUT
    nil
  end

  def new_vm_name
    @new_vm_name ||= "#{@name}-#{@version}"
  end

  def create_user
    if version =~/1.5/
      body= "user[user_name]=#{@username}&user[password]=#{@password}&user[password_confirmantion]=#{@password}"
      uri= "/api/users"
    elsif version=~/1.6/
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
