require 'rbvmomi'
require 'rbvmomi/utils/deploy'
require 'rbvmomi/utils/admission_control'
require 'rbvmomi/utils/leases'
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
				dc = vim.serviceInstance.find_datacenter(config[:opts][:vcenter][:datacenter])

				root_vm_folder = dc.vmFolder
				vm_folder = root_vm_folder
				template_folder = root_vm_folder.traverse!('templates', RbVmomi::VIM::Folder)
        print "====> extracting #{config[:ova_path]}...".green
					
        logger.info `tar xvzf #{config[:ova_path]}`
        
        logger.info 'creating admission controlled resource'
				scheduler = AdmissionControlledResourceScheduler.new(
					vim,
					datacenter: dc,
					computer_names: [config[:opts][:vcenter][:cluster]],
          vm_folder: vm_folder,
					rp_path: '/',
					datastore_paths: [config[:opts][:datastore]],
				)
        logger.info 'making placement'
				scheduler.make_placement_decision


				datastore = scheduler.datastore
				computer = scheduler.pick_computer
				network = computer.network.find{|x| x.name == config[:opts][:portgroup]}

				lease_tool = LeaseTool.new
				lease = 3 * 24 * 60 * 60 # 3 days
				deployer = CachedOvfDeployer.new(vim, network, computer, template_folder, vm_folder, datastore)

        print '====> Uploading/Preparing OVF template ...'.green

				template = deployer.upload_ovf_as_template( 
          Dir.glob("*.ovf").first,
					"opsman-#{config[:desired_version]}",
					run_without_interruptions: true,
					config:  lease_tool.set_lease_in_vm_config({}, lease)
				)
        # FIXME: don't use linked_clone here, either clone the template directly,
        #        and then add vapp config via some other method, or posibly convert
        #        to using deployOVF (https://github.com/vmware/rbvmomi/blob/2e427817735e5df0aef1baa07bc95762e45a18bc/lib/rbvmomi/vim/OvfManager.rb)
        print '====> Cloning template  ...'.green
				vm = deployer.linked_clone(
          template, 
          vm_name, 
					lease_tool.set_lease_in_vm_config({
            extraConfig: [
              {
                key: 'ip0',            
                value: config[:ip]
              }
            ] 
          }, lease))
         
#            'admin_password' => config[:password],
#            'admin_username' => config[:username],
#            'netmask0'       => config[:opts][:netmask],
#            'dns'            => config[:opts][:dns],
#            'ntp_servers'    => config[:opts][:ntp_servers].join(','),
#            'gateway'        => config[:opts][:gateway]}

        print '====> Powering on VM...'.green
				vm.PowerOnVM_Task.wait_for_completion
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


