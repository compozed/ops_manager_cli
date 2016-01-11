require "ops_manager_deployer/deployment"
require 'rbvmomi'
require "uri"
require "ops_manager_deployer/logging"
require "byebug"

class OpsManagerDeployer::Vsphere < OpsManagerDeployer::Deployment
  include OpsManagerDeployer::Logging

  def initialize(name, ip, username, password, opts)
    @name, @ip, @username, @password, @opts = name, ip, username, password, opts
  end

  def deploy
    deploy_ova
    until( create_user.code.to_i == 200) do
      print '.' ; sleep 1
    end
  end

  def upgrade
    get_installation_assets
    get_installation_settings
    stop_current_vm
    deploy
    upload_installation_assets
    # upload_installation_settings
  end

  def new_version
    opts.fetch('version')
  end

  def get_installation_assets
    res = get("/api/installation_asset_collection")
    if res.code.to_i == 200
      open("installation_assets.zip", "wb") do |file|
        file.write(res.body)
      end
    end
    res
  end

  def upload_installation_assets
    zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
    res = multipart_post( "/api/installation_asset_collection",
      :password => @password,
      "installation[file]" => zip
    )
    res
  end

  def upload_installation_settings
    # json is Yaml compatible
    yml = UploadIO.new("#{Dir.pwd}/installation_settings.json", 'application/x-yaml')
    res = multipart_post( "/api/installation_settings",
      :password => @password,
      "installation[file]" => yml
    )
    puts res.body
    res
  end

  def get_installation_settings
    res = get("/api/installation_settings")
    if res.code.to_i == 200
      open("installation_settings.json", "wb") do |file|
        file.write(res.body)
      end
    end
    res
  end

  private
  def stop_current_vm
    dc = vim.serviceInstance.find_datacenter(vcenter.fetch('datacenter'))
    logger.info "finding vm: #{current_vm_name}"
    vm = dc.find_vm(current_vm_name) or fail "VM not found"
    vm.PowerOffVM_Task.wait_for_completion
  end

  def vim
    RbVmomi::VIM.connect host: vcenter.fetch('host'), user: URI.unescape(vcenter.fetch('username')), password: URI.unescape(vcenter.fetch('password')), insecure: true
  end


  def deploy_ova
    logger.info 'Starts ova deployment'
    target= "vi://#{@opts['vcenter']['username']}:#{@opts['vcenter']['password']}@#{@opts['vcenter']['host']}/#{@opts['vcenter']['datacenter']}/host/#{@opts['vcenter']['cluster']}"
    cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{@opts['portgroup']}\" --name=#{new_vm_name} -ds=#{@opts['datastore']} --prop:ip0=#{@ip} --prop:netmask0=#{@opts['netmask']}  --prop:gateway=#{@opts['gateway']} --prop:DNS=#{@opts['dns']} --prop:ntp_servers=#{@opts['ntp_servers'].join(',')} --prop:admin_password=#{@password} #{@opts['ova_path']} #{target}"
    logger.info cmd
    puts `#{cmd}`
    logger.info 'Finished ova deployment'
  end


  def vcenter
    opts.fetch('vcenter')
  end

  def new_vm_name
    @new_vm_name ||= "#{@name}-#{opts.fetch('version')}"
  end
end

