require "ops_manager_deployer/cloud"
require "uri"
require "ops_manager_deployer/logging"

class OpsManagerDeployer::Vsphere < OpsManagerDeployer::Cloud
  include OpsManagerDeployer::Logging

  def initialize(ip, username, password, opts)
    @ip, @username, @password, @opts = ip, username, password, opts
  end

  def deploy
    deploy_ova
    until( create_user.code.to_i == 200) do
      puts '.' ; sleep 1
    end
  end

  def upgrade
    get_installation_assets
    get_installation_settings
  end

  def get_installation_assets
    open("installation_assets_#{@ip}.zip", "wb") do |file|
      file.write(get("/api/installation_asset_collection").body)
    end
  end

  def get_installation_settings
    open("installation_settings.json", "wb") do |file|
      file.write(get("/api/installation_settings").body)
    end
  end

  private
  def deploy_ova
    logger.info 'Starts ova deployment'
    cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{@opts['portgroup']}\" --name=#{@opts['name']} -ds=#{@opts['datastore']} --prop:ip0=#{@ip} --prop:netmask0=#{@opts['netmask']}  --prop:gateway=#{@opts['gateway']} --prop:DNS=#{@opts['dns']} --prop:ntp_servers=#{@opts['ntp_servers'].join(',')} --prop:admin_password=#{@password} #{@opts['ova_path']} #{@opts['target']}"
    logger.info cmd
    puts `#{cmd}`
    logger.info 'Finished ova deployment'
  end

  def create_user
    post("/api/users",
         body: "user[user_name]=#{@username}&user[password]=#{@password}&user[password_confirmantion]=#{@password}")
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
      request.body=opts.fetch( :body )
    end

    http.request(request)
  end
end

