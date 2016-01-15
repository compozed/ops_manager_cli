require 'spec_helper'

describe OpsManager::Vsphere do
  let(:assets_zipfile){ "installation_assets.zip" }
  let(:conf_file){'ops_manager_deployment.yml'}
  let(:name){ conf.fetch('name') }
  let(:target){ OpsManager.get_conf :target }
  let(:username){ OpsManager.get_conf :username }
  let(:password){ OpsManager.get_conf :password }

  let(:conf){ YAML.load_file(conf_file) }
  let(:vcenter_username){ vcenter.fetch('username') }
  let(:vcenter_password){ vcenter.fetch('password') }
  let(:vcenter_datacenter){ vcenter.fetch('datacenter') }
  let(:vcenter_cluster){ vcenter.fetch('cluster') }
  let(:vcenter_host){ vcenter.fetch('host') }
  let(:vcenter){ opts.fetch('vcenter') }
  let(:opts){ conf.fetch('opts') }
  let(:current_version){ '1.4.2.0' }
  let(:new_version){ opts.fetch('version') }
  let(:current_vm_name){ "#{name}-#{vsphere.current_version}"}
  let(:new_vm_name){ "#{name}-#{opts.fetch('version')}"}
  let(:vsphere){ described_class.new(name, target, username, password, opts) }

  before do
    OpsManager.target('1.2.3.4')
    OpsManager.login('foo', 'bar')
  end

  it 'should inherit from deployment' do
    expect(described_class).to be < OpsManager::Deployment
  end

  it 'should include logging' do
    expect(vsphere).to be_kind_of(OpsManager::Logging)
  end

  describe 'deploy' do
    let(:vcenter_target){"vi://#{vcenter_username}:#{vcenter_password}@#{vcenter_host}/#{vcenter_datacenter}/host/#{vcenter_cluster}"}

    it 'Should perform in the right order' do
      %i( deploy_ova create_first_user).each do |m|
        expect(vsphere).to receive(m).ordered
      end
      vsphere.deploy
    end

    it 'should run ovftools successfully' do
      VCR.turned_off do
        allow(vsphere).to receive(:current_version).and_return(current_version)
        expect(vsphere).to receive(:`).with("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{new_vm_name} -ds=#{opts['datastore']} --prop:ip0=#{target} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{password} #{opts['ova_path']} #{vcenter_target}")
        vsphere.deploy_ova
      end
    end

    it 'should create the first user' do
      VCR.use_cassette 'create first user', record: :none do
        expect(vsphere).to receive(:create_user).twice.and_call_original
        vsphere.create_first_user
      end
    end
  end

  describe 'upgrade' do
    before  do
      allow(vsphere).to receive(:current_version).and_call_original
      `rm -rf assets *.zip installation_settings.json`
    end

    it 'Should perform in the right order' do
      %i( get_installation_assets get_installation_settings
         stop_current_vm deploy upload_installation_assets ).each do |m|
        expect(vsphere).to receive(m).ordered
      end
      vsphere.upgrade
    end

    it 'should download installation_assets' do
      VCR.use_cassette 'installation assets download' do
        vsphere.get_installation_assets
        expect(File).to exist(assets_zipfile)
        `unzip #{assets_zipfile} -d assets`
        expect(File).to exist("assets/deployments/bosh-deployments.yml")
        expect(File).to exist("assets/installation.yml")
        expect(File).to exist("assets/metadata/microbosh.yml")
      end
    end

    it 'should download installation_settings' do
      expected_json = JSON.parse(File.read('../fixtures/pretty_installation_settings.json'))

      VCR.use_cassette 'installation settings download' do
        vsphere.get_installation_settings
        expect( JSON.parse(File.read('installation_settings.json'))).to eq(expected_json)
      end
    end

    it 'should stops current vm to release IP' do
      allow(vsphere).to receive(:get_installation_settings)
      allow(vsphere).to receive(:get_installation_assets)
      allow(vsphere).to receive(:deploy)
      allow(vsphere).to receive(:upload_installation_assets)

      VCR.use_cassette 'stopping vm' do
        expect(RbVmomi::VIM).to receive(:connect).with({ host: vcenter_host, user: vcenter_username , password: vcenter_password , insecure: true}).and_call_original
        expect_any_instance_of(RbVmomi::VIM::ServiceInstance).to receive(:find_datacenter).with(vcenter_datacenter).and_call_original
        expect_any_instance_of(RbVmomi::VIM::Datacenter).to receive(:find_vm).with(current_vm_name).and_call_original
        expect_any_instance_of(RbVmomi::VIM::VirtualMachine).to receive(:PowerOffVM_Task).and_call_original
        vsphere.upgrade
      end
    end

    it 'should deploy' do # reuse and test
      allow(vsphere).to receive(:get_installation_settings)
      allow(vsphere).to receive(:get_installation_assets)
      allow(vsphere).to receive(:stop_current_vm)
      expect(vsphere).to receive(:deploy)
      allow(vsphere).to receive(:upload_installation_assets)

      vsphere.upgrade
    end

    # For updating VCR casset you need to:
    # - point spec/dummy/vsphere.yml to existing vanilla ops-manager
    it 'should upload installation_assets' do
      VCR.use_cassette 'uploading assets' do
        expect do
          `rm installation_assets.zip`
          `cp ../fixtures/installation_assets.zip .`
          vsphere.upload_installation_assets
        end.to change{ vsphere.get_installation_assets.code.to_i }.from(500).to(200)
      end
    end
  end
end
