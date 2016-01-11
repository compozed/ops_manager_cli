require 'spec_helper'

describe OpsManagerDeployer::Vsphere do
  let(:assets_zipfile){ "installation_assets.zip" }
  let(:conf_file){'vsphere.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:vcenter_username){ vcenter.fetch('username') }
  let(:vcenter_password){ vcenter.fetch('password') }
  let(:vcenter_datacenter){ vcenter.fetch('datacenter') }
  let(:vcenter_cluster){ vcenter.fetch('cluster') }
  let(:vcenter_host){ vcenter.fetch('host') }
  let(:name){ conf.fetch('name') }
  let(:username){ conf.fetch('username') }
  let(:password){ conf.fetch('password') }
  let(:vcenter){ opts.fetch('vcenter') }
  let(:opts){ conf.fetch('deployment').fetch('opts') }
  let(:current_version){ '1.4.2.0' }
  let(:new_version){ opts.fetch('version') }
  let(:current_vm_name){ "#{name}-#{vsphere.current_version}"}
  let(:new_vm_name){ "#{name}-#{opts.fetch('version')}"}
  let(:vsphere){ described_class.new(name, conf.fetch('ip'), username, password, opts) }


  it 'should inherit from deployment' do
    expect(described_class).to be < OpsManagerDeployer::Deployment
  end

  it 'should include logging' do
    expect(vsphere).to be_kind_of(OpsManagerDeployer::Logging)
  end

  describe 'deploy' do
    let(:target){"vi://#{vcenter_username}:#{vcenter_password}@#{vcenter_host}/#{vcenter_datacenter}/host/#{vcenter_cluster}"}

    it 'should run ovftools successfully' do
      VCR.turned_off do
        allow(vsphere).to receive(:current_version).and_return(current_version)
        allow(vsphere).to receive(:create_user).and_return(double(code: 200))
        expect(vsphere).to receive(:`).with("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{new_vm_name} -ds=#{opts['datastore']} --prop:ip0=#{conf['ip']} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{conf['password']} #{opts['ova_path']} #{target}")
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
      allow(vsphere).to receive(:current_version).and_call_original
      `rm -rf assets *.zip installation_settings.json`
    end

    it 'should download installation_assets' do
      allow(vsphere).to receive(:get_installation_settings)
      allow(vsphere).to receive(:stop_current_vm)
      allow(vsphere).to receive(:deploy)
      allow(vsphere).to receive(:upload_installation_assets)

      VCR.use_cassette 'installation assets download' do
        vsphere.upgrade
        expect(File).to exist(assets_zipfile)
        `unzip #{assets_zipfile} -d assets`
        expect(File).to exist("assets/deployments/bosh-deployments.yml")
        expect(File).to exist("assets/installation.yml")
        expect(File).to exist("assets/metadata/microbosh.yml")
      end
    end

    it 'should download installation_settings' do
      allow(vsphere).to receive(:deploy)
      allow(vsphere).to receive(:stop_current_vm)
      allow(vsphere).to receive(:get_installation_assets)
      allow(vsphere).to receive(:upload_installation_assets)

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
          `rm ../dummy/installation_assets.zip`
          `cp ../fixtures/installation_assets.zip .`
          vsphere.upload_installation_assets
        end.to change{ vsphere.get_installation_assets.code.to_i }.from(500).to(200)
      end
    end

    pending 'should upload installation_settings' do
      VCR.use_cassette 'uploading settings' do
        `rm ../dummy/installation_settings.json`
          `cp ../fixtures/installation_settings_for_upload.json installation_settings.json`
          res = vsphere.upload_installation_settings
          expect(res.code.to_i).to eq(200)
      end
    end
  end
end
