require "ops_manager/deployment"
require 'rbvmomi'
require "uri"
require "ops_manager/logging"

class OpsManager::Vsphere < OpsManager::Deployment
  include OpsManager::Logging
  attr_reader :opts

  def initialize(name, ip, username, password, opts)
    @name, @ip, @username, @password, @opts = name, ip, username, password, opts
    super(@name, opts.fetch('version'))

  end

  def deploy_vm
    puts '====> Starts ova deployment'.green
    target= "vi://#{@opts['vcenter']['username']}:#{@opts['vcenter']['password']}@#{@opts['vcenter']['host']}/#{@opts['vcenter']['datacenter']}/host/#{@opts['vcenter']['cluster']}"
    cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{@opts['portgroup']}\" --name=#{new_vm_name} -ds=#{@opts['datastore']} --prop:ip0=#{@ip} --prop:netmask0=#{@opts['netmask']}  --prop:gateway=#{@opts['gateway']} --prop:DNS=#{@opts['dns']} --prop:ntp_servers=#{@opts['ntp_servers'].join(',')} --prop:admin_password=#{@password} #{@opts['ova_path']} #{target}"
    logger.info cmd
    puts `#{cmd}`
  end

  def stop_current_vm
    puts '====> Stopping current vm...'.green
    dc = vim.serviceInstance.find_datacenter(vcenter.fetch('datacenter'))
    logger.info "finding vm: #{current_vm_name}"
    vm = dc.find_vm(current_vm_name) or fail "VM not found"
    vm.PowerOffVM_Task.wait_for_completion
  end

  private
  def vcenter
    opts.fetch('vcenter')
  end

  def vim
    RbVmomi::VIM.connect host: vcenter.fetch('host'), user: URI.unescape(vcenter.fetch('username')), password: URI.unescape(vcenter.fetch('password')), insecure: true
  end
end

