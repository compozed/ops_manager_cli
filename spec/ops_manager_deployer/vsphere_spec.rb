require 'spec_helper'

describe OpsManagerDeployer::Vsphere do
  let(:conf_file){'vsphere.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:opts){ conf.fetch('deployment').fetch('opts') }
  let(:current_version){ '1.4.2.0' }
  let(:current_vm_name){ "#{conf.fetch('name')}-#{current_version}"}
  let(:vsphere){ described_class.new(conf.fetch('name'), conf.fetch('ip'), conf.fetch('username'), conf.fetch('password'), opts) }


  it 'should inherit from deployment' do
    expect(described_class).to be < OpsManagerDeployer::Deployment
  end

  it 'should include logging' do
    expect(vsphere).to be_kind_of(OpsManagerDeployer::Logging)
  end

  describe 'deploy' do
    let(:target){'vi://VM_VCENTER_USER:VM_VCENTER_PASSWORD@VM_VCENTER/VM_DATACENTER/host/VM_CLUSTER'}

    it 'should run ovftools successfully' do
      VCR.turned_off do
        allow(vsphere).to receive(:current_version).and_return(current_version)
        allow(vsphere).to receive(:create_user).and_return(double(code: 200))
        expect(vsphere).to receive(:`).with("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{current_vm_name} -ds=#{opts['datastore']} --prop:ip0=#{conf['ip']} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{conf['password']} #{opts['ova_path']} #{target}")
        vsphere.deploy
      end
    end

    it 'should create the first user' do
        VCR.use_cassette 'create first user', record: :none do
        allow(vsphere).to receive(:deploy_ova)
          expect(vsphere).to receive(:create_user).twice.and_call_original
        vsphere.deploy
      end
    end
  end

  describe 'upgrade' do

    before  do
        allow(vsphere).to receive(:current_version).and_return(current_version)
      `rm -rf assets *.zip installation_settings.json`
    end

    it 'should download installation_assets' do
      allow(vsphere).to receive(:get_installation_settings)
      allow(vsphere).to receive(:deploy)

      VCR.use_cassette 'installation assets download' do
        vsphere.upgrade
        zipfile = "installation_assets_#{conf.fetch('ip')}.zip"
        expect(File).to exist(zipfile)
        `unzip #{zipfile} -d assets`
        expect(File).to exist("assets/deployments/bosh-deployments.yml")
        expect(File).to exist("assets/installation.yml")
        expect(File).to exist("assets/metadata/microbosh.yml")
      end
    end

    it 'should download installation_settings' do
      allow(vsphere).to receive(:deploy)
      expected_json = JSON.parse(File.read('../fixtures/pretty_installation_settings.json'))

      VCR.use_cassette 'installation settings download' do
        vsphere.upgrade
        expect( JSON.parse(File.read('installation_settings.json'))).to eq(expected_json)
      end
    end

    it 'should stops current vm to release IP' do
      allow(vsphere).to receive(:get_installation_settings)
      allow(vsphere).to receive(:get_installation_assets)
      allow(vsphere).to receive(:deploy)
        expect(vsphere).to receive(:`).with("echo 'vm.shutdown_guest /VM_VCENTER/VM_DATACENTER/vms/#{current_vm_name}' | rvc VM_VCENTER_USER:VM_VCENTER_PASSWORD@VM_VCENTER")
        vsphere.upgrade
    end

    it 'should deploy' do # reuse and test

      allow(vsphere).to receive(:get_installation_settings)
      allow(vsphere).to receive(:get_installation_assets)
      allow(vsphere).to receive(:stop_current_vm)
      expect(vsphere).to receive(:deploy)

      vsphere.upgrade
    end

    it 'should upload installation_assets'
    it 'should upload installation_settings'
  end
end
