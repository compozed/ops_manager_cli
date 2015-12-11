require 'spec_helper'

describe OpsManagerDeployer::Vsphere do
  # let(:conf_file){"#{ENV['HOME']}/workspace/deployments/lab-nb99/ops-manager/ops_manager_deployer.yml"}
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
end
