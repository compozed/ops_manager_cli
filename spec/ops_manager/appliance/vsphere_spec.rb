require 'spec_helper'

describe OpsManager::Appliance::Vsphere do
  let(:vsphere){ described_class.new(config) }
  let(:config) do
    {
      name: 'ops-manager',
      provider: 'vsphere',
      desired_version: '1.4.11.0',
      ip: '1.2.3.4',
      username: 'foo',
      password: 'bar',
      pivnet_token: 'abc123',
      opts: {
        ova_path: 'ops-manager.ova', # you can also specify the path with *. e.g.: ops-manager-ova/*.ova. This is usefull when using concourse and the pivnet-resource
        portgroup: 'dummy-portgroup',
        netmask: '255.255.255.0',
        gateway: '1.2.3.1',
        dns: '8.8.8.8',
        datastore: 'DS1',
        vcenter: {
          username: 'VM_VCENTER_USER',
          password: 'VM_VCENTER_PASSWORD',
          host: '1.2.3.2',
          datacenter: 'VM_DATACENTER',
          cluster: 'VM_CLUSTER'
        },
        ntp_servers: [ 'clock1.example.com', 'clock2.example.com']
      }
    }
  end
  let(:current_version){ '1.4.2.0' }
  let(:current_vm_name){ "ops-manager-1.4.2.0"}

  before do
    OpsManager.set_conf(:target, '1.2.3.4')
    OpsManager.set_conf(:username, 'foo')
    OpsManager.set_conf(:username, 'bar')
  end


  xit 'should include logging' do
    expect(vsphere).to be_kind_of(OpsManager::Logging)
  end

  describe 'deploy_vm' do
    subject(:deploy_vm){ vsphere.deploy_vm }
    let(:vcenter_target){"vi://VM_VCENTER_USER:VM_VCENTER_PASSWORD@1.2.3.2/VM_DATACENTER/host/VM_CLUSTER"}

    it 'should run ovftools successfully' do
      allow(vsphere).to receive(:cmd).and_return("(exit 0)")
      deploy_vm
    end

    it 'should run ovftools and handle errors' do
      # expect to fail?
      expect {deploy_vm}.to raise_error("Failure in ovftool")
    end

  end

  describe 'cmd' do
    subject(:cmd){ vsphere.cmd }
    let(:vcenter_target){"vi://VM_VCENTER_USER:VM_VCENTER_PASSWORD@1.2.3.2/VM_DATACENTER/host/VM_CLUSTER"}
    it 'returns the right command' do
      cmd = vsphere.cmd
      expect(cmd).to eq("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{config[:opts][:portgroup]}\" --name=ops-manager-1.4.11.0 -ds=#{config[:opts][:datastore]} --prop:ip0=1.2.3.4 --prop:netmask0=#{config[:opts][:netmask]}  --prop:gateway=#{config[:opts][:gateway]} --prop:DNS=#{config[:opts][:dns]} --prop:ntp_servers=#{config[:opts][:ntp_servers].join(',')} --prop:admin_password=#{config[:password]} #{config[:opts][:ova_path]} #{vcenter_target}")
    end

    %i{username password}.each do |m|
      describe "when vcenter_#{m} has unescaped character" do
        before { config[:opts][:vcenter][m] = "domain\\vcenter_+)#{m}" }
        

        it "should URL encode the #{m}" do
          cmd = vsphere.cmd
          expect(cmd).to match(/domain\\%5Cvcenter_\\\+\\\)#{m}/)
        end
      end
    end
  end

  describe 'stop_current_vm' do
    let(:vm_name){ 'ops-manager-1.4.2.0' }
    subject(:stop_current_vm) { vsphere.stop_current_vm(vm_name) }

    xit 'should stops current vm to release IP' do
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
