require 'spec_helper'

describe OpsManagerDeployer::Vsphere do
  let(:conf_file){'vsphere.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:opts){ conf.fetch('cloud').fetch('opts') }
  let(:vsphere){ described_class.new(conf.fetch('ip'), conf.fetch('username'), conf.fetch('password'), opts) }


  it 'should inherit from cloud' do
    expect(described_class).to be < OpsManagerDeployer::Cloud
  end

  it 'should include logging' do
    expect(vsphere).to be_kind_of(OpsManagerDeployer::Logging)
  end

  describe 'deploy' do
    it 'should run ovftools successfully' do
      VCR.turned_off do
        allow(vsphere).to receive(:create_user).and_return(double(code: 200))
        expect(vsphere).to receive(:`).with("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{opts['name']} -ds=#{opts['datastore']} --prop:ip0=#{conf['ip']} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{conf['password']} #{opts['ova_path']} #{opts['target']}")
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
    before{ `rm -rf assets *.zip installation_settings.json` }

    it 'should download installation_assets' do
      allow(vsphere).to receive(:get_installation_settings)

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
      expected_json = JSON.parse(File.read('../fixtures/pretty_installation_settings.json'))

      VCR.use_cassette 'installation settings download' do
        vsphere.upgrade
        expect( JSON.parse(File.read('installation_settings.json'))).to eq(expected_json)
      end
    end

    it 'should stops current vm to release IP'
    it 'should deploy' # reuse and test
    it 'should upload installation_assets'
    it 'should upload installation_settings'
  end
end
