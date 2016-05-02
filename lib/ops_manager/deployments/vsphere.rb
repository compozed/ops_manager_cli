require "ops_manager/deployments/base"
require 'rbvmomi'
require "uri"
require "ops_manager/logging"

module OpsManager::Deployments::Vsphere
  include OpsManager::Logging
  include OpsManager::Logging

  def deploy_vm(name, ip)
    puts '====> Starts ova deployment'.green
    vcenter_target= "vi://#{vcenter_username}:#{vcenter_password}@#{config.opts['vcenter']['host']}/#{config.opts['vcenter']['datacenter']}/host/#{config.opts['vcenter']['cluster']}"
    cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{config.opts['portgroup']}\" --name=#{name} -ds=#{config.opts['datastore']} --prop:ip0=#{ip} --prop:netmask0=#{config.opts['netmask']}  --prop:gateway=#{config.opts['gateway']} --prop:DNS=#{config.opts['dns']} --prop:ntp_servers=#{config.opts['ntp_servers'].join(',')} --prop:admin_password=#{config.password} #{config.opts['ova_path']} #{vcenter_target}"
    logger.info cmd
    puts `#{cmd}`
  end

  def stop_current_vm(name)
    puts "====> Stopping vm #{name}...".green
    dc = vim.serviceInstance.find_datacenter(config.opts['vcenter']['datacenter'])
    logger.info "finding vm: #{name}"
    vm = dc.find_vm(name) or fail "VM not found"
    vm.PowerOffVM_Task.wait_for_completion
  end

  private
  def vim
    RbVmomi::VIM.connect host: config.opts['vcenter']['host'], user: URI.unescape(config.opts['vcenter']['username']), password: URI.unescape(config.opts['vcenter']['password']), insecure: true
  end

  def vcenter_username
    URI.encode(config.opts['vcenter']['username'])
  end

  def vcenter_password
    URI.encode(config.opts['vcenter']['password'])
  end
end

