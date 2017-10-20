require 'rbvmomi'
require "uri"
require 'shellwords'
require "ops_manager/logging"
require 'ops_manager/appliance/base'

class OpsManager
  module Appliance
    class Vsphere < Base
      include OpsManager::Logging
      attr_reader :config

      def deploy_vm
        print '====> Deploying ova ...'.green
        vcenter_target= "vi://#{vcenter_username}:#{vcenter_password}@#{config[:opts][:vcenter][:host]}/#{config[:opts][:vcenter][:datacenter]}/host/#{config[:opts][:vcenter][:cluster]}"
        cmd = "echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{config[:opts][:portgroup]}\" --name=#{vm_name} -ds=#{config[:opts][:datastore]} --prop:ip0=#{config[:ip]} --prop:netmask0=#{config[:opts][:netmask]}  --prop:gateway=#{config[:opts][:gateway]} --prop:DNS=#{config[:opts][:dns]} --prop:ntp_servers=#{config[:opts][:ntp_servers].join(',')} --prop:admin_password=#{config[:password]} #{config[:opts][:ova_path]} #{vcenter_target}"
        logger.info "Running: #{cmd}"
        logger.info `#{cmd}`
        puts 'done'.green
      end

      def stop_current_vm(name)
        print "====> Stopping vm #{name} ...".green
        dc = vim.serviceInstance.find_datacenter(config[:opts][:vcenter][:datacenter])
        logger.info "finding vm: #{name}"
        vm = dc.find_vm(name) or fail "VM not found"
        vm.PowerOffVM_Task.wait_for_completion
        puts 'done'.green
      end

      private
      def vim
        RbVmomi::VIM.connect host: config[:opts][:vcenter][:host], user: URI.unescape(config[:opts][:vcenter][:username]), password: URI.unescape(config[:opts][:vcenter][:password]), insecure: true
      end

      def vcenter_username
        Shellwords.escape(URI.encode(config[:opts][:vcenter][:username]))
      end

      def vcenter_password
        Shellwords.escape(URI.encode(config[:opts][:vcenter][:password]))
      end
    end
  end
end


