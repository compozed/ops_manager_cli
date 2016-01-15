require "ops_manager/deployment"
require 'rbvmomi'
require "uri"
require "ops_manager/logging"

class OpsManager::Vsphere < OpsManager::Deployment
  include OpsManager::Logging

  def initialize(name, ip, username, password, opts)
    @name, @ip, @username, @password, @opts = name, ip, username, password, opts
  end

  def deploy
    deploy_ova
    create_first_user
  end

  def deploy_ova
    puts '====> Starts ova deployment'.green
    target= "vi://#{@opts['vcenter']['username']}:#{@opts['vcenter']['password']}@#{@opts['vcenter']['host']}/#{@opts['vcenter']['datacenter']}/host/#{@opts['vcenter']['cluster']}"
    cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{@opts['portgroup']}\" --name=#{new_vm_name} -ds=#{@opts['datastore']} --prop:ip0=#{@ip} --prop:netmask0=#{@opts['netmask']}  --prop:gateway=#{@opts['gateway']} --prop:DNS=#{@opts['dns']} --prop:ntp_servers=#{@opts['ntp_servers'].join(',')} --prop:admin_password=#{@password} #{@opts['ova_path']} #{target}"
    logger.info cmd
    puts `#{cmd}`
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

  def new_version
    opts.fetch('version')
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

  private
  def stop_current_vm
    puts '====> Stopping current vm...'.green
    dc = vim.serviceInstance.find_datacenter(vcenter.fetch('datacenter'))
    logger.info "finding vm: #{current_vm_name}"
    vm = dc.find_vm(current_vm_name) or fail "VM not found"
    vm.PowerOffVM_Task.wait_for_completion
  end

  def vim
    RbVmomi::VIM.connect host: vcenter.fetch('host'), user: URI.unescape(vcenter.fetch('username')), password: URI.unescape(vcenter.fetch('password')), insecure: true
  end


  def vcenter
    opts.fetch('vcenter')
  end

  def new_vm_name
    @new_vm_name ||= "#{@name}-#{opts.fetch('version')}"
  end
  def opts
    @opts
  end
end

