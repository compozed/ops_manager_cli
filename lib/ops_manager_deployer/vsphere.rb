require "ops_manager_deployer/cloud"
    require "uri"

class OpsManagerDeployer::Vsphere < OpsManagerDeployer::Cloud
  def initialize(ip, username, password, opts)
    @ip, @username, @password, @opts = ip, username, password, opts
  end

  def deploy
    deploy_ova
    create_user
  end


  private
  def deploy_ova
    `echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{opts['name']} -ds=#{opts['datastore']} --prop:ip0=#{@ip} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{@password} #{opts['ova_path']} #{opts['target']}`
  end

  def create_user
    uri = URI.parse("https://#{@ip}/api/users")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(
      'user' => {
        'user_name' => @username,
        'password' => @password,
        'password_confirmantion' => @password }
    )
    response = http.request(request)
  end

  def opts ; @opts end
end

