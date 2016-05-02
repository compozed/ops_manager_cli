require 'spec_helper'

describe OpsManager::Deployments::Vsphere do
  class Foo ; include OpsManager::Deployments::Vsphere ; end
  let(:conf_file){'ops_manager_deployment.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:name){ conf.fetch('name') }
  let(:target){ conf.fetch('ip') }
  let(:username){ conf.fetch('username') }
  let(:password){ conf.fetch('password') }
  let(:vcenter_username){ vcenter.fetch('username') }
  let(:vcenter_password){ vcenter.fetch('password') }
  let(:vcenter_datacenter){ vcenter.fetch('datacenter') }
  let(:vcenter_cluster){ vcenter.fetch('cluster') }
  let(:vcenter_host){ vcenter.fetch('host') }
  let(:vcenter){ config.opts.fetch('vcenter') }
  let(:config){ OpsManager::Configs::OpsmanDeployment.new(::YAML.load_file('ops_manager_deployment.yml') )}
  let(:current_version){ '1.4.2.0' }
  let(:current_vm_name){ "#{name}-#{current_version}"}
  let(:vm_name){ 'ops-manager-1.4.11.0' }
  let(:vsphere){ Foo.new }

  before do
    allow(vsphere).to receive(:config).and_return(config)
    OpsManager.set_conf(:target, '1.2.3.4')
    OpsManager.set_conf(:username, 'foo')
    OpsManager.set_conf(:username, 'bar')
  end


  xit 'should include logging' do
    expect(vsphere).to be_kind_of(OpsManager::Logging)
  end

  describe 'deploy_vm' do
    subject(:deploy_vm){ vsphere.deploy_vm(vm_name, target) }
    let(:vcenter_target){"vi://#{vcenter_username}:#{vcenter_password}@#{vcenter_host}/#{vcenter_datacenter}/host/#{vcenter_cluster}"}

    it 'should run ovftools successfully' do
      expect(vsphere).to receive(:`).with("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{config.opts['portgroup']}\" --name=#{vm_name} -ds=#{config.opts['datastore']} --prop:ip0=#{target} --prop:netmask0=#{config.opts['netmask']}  --prop:gateway=#{config.opts['gateway']} --prop:DNS=#{config.opts['dns']} --prop:ntp_servers=#{config.opts['ntp_servers'].join(',')} --prop:admin_password=#{password} #{config.opts['ova_path']} #{vcenter_target}")
      deploy_vm
    end

    %w{username password}.each do |m|
      describe "when vcenter_#{m} has unescaped character" do
        before { config.opts['vcenter'][m] = "domain\\vcenter_#{m}" }

        it "should URL encode the #{m}" do
          expect(vsphere).to receive(:`).with(/domain%5Cvcenter_#{m}/)
          deploy_vm
        end
      end
    end
  end


  describe 'stop_current_vm' do
    let(:vm_name){ 'ops-manager-1.4.2.0' }
    subject(:stop_current_vm) { vsphere.stop_current_vm(vm_name) }

    it 'should stops current vm to release IP' do
      VCR.use_cassette 'stopping vm' do
        expect(RbVmomi::VIM).to receive(:connect).with({ host: vcenter_host, user: vcenter_username , password: vcenter_password , insecure: true}).and_call_original
        expect_any_instance_of(RbVmomi::VIM::ServiceInstance).to receive(:find_datacenter).with(vcenter_datacenter).and_call_original
        expect_any_instance_of(RbVmomi::VIM::Datacenter).to receive(:find_vm).with(current_vm_name).and_call_original
        expect_any_instance_of(RbVmomi::VIM::VirtualMachine).to receive(:PowerOffVM_Task).and_call_original
        stop_current_vm
      end
    end
  end
end
