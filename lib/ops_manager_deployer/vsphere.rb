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


  private
  def deploy_ova
    logger.info 'Starts ova deployment'
    cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{opts['name']} -ds=#{opts['datastore']} --prop:ip0=#{@ip} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{@password} #{opts['ova_path']} #{opts['target']}"
    logger.info cmd
    puts `#{cmd}`
    logger.info 'Finished ova deployment'
  end

  def create_user
    uri = URI.parse("https://#{@ip}/api/users")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri )
    request.body="user[user_name]=#{@username}&user[password]=#{@password}&user[password_confirmantion]=#{@password}"
    logger.info("User creation request: #{request.inspect}")
    response = http.request(request)
    logger.info("User creation response: #{response.inspect}")
    logger.info("User creation response body: #{response.body}")
    logger.info("User creation response code: #{response.code}")
    response
  end

  def opts ; @opts end
end

