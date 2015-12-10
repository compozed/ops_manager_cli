require 'spec_helper'

describe OpsManagerDeployer::Vsphere do
  let(:conf_file){'vsphere.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:opts){ conf.fetch('cloud').fetch('opts') }
  let(:vsphere){ described_class.new(conf.fetch('ip'), conf.fetch('username'), conf.fetch('password'), opts) }


  it 'should inherit from cloud' do
    expect(described_class).to be < OpsManagerDeployer::Cloud
  end

  describe 'deploy' do
    it 'should run ovftools successfully' do
      VCR.turned_off do
        allow(vsphere).to receive(:create_user)
        expect(vsphere).to receive(:`).with("echo yes | ovftool --acceptAllEulas --noSSLVerify --powerOn --X:waitForIp --net:\"Network 1=#{opts['portgroup']}\" --name=#{opts['name']} -ds=#{opts['datastore']} --prop:ip0=#{conf['ip']} --prop:netmask0=#{opts['netmask']}  --prop:gateway=#{opts['gateway']} --prop:DNS=#{opts['dns']} --prop:ntp_servers=#{opts['ntp_servers'].join(',')} --prop:admin_password=#{conf['password']} #{opts['ova_path']} #{opts['target']}")
        vsphere.deploy
      end
    end

    it 'should create the first user' do
      VCR.turned_off do
        allow(vsphere).to receive(:deploy_ova)
        stub_request(:post, "https://#{conf['ip']}/api/users").
          with(:body => {"user"=>"{\"user_name\"=>\"#{conf['username']}\", \"password\"=>\"#{conf['password']}\", \"password_confirmantion\"=>\"#{conf['password']}\"}"},
               :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

        vsphere.deploy

        expect(WebMock).to have_requested(:post, "https://#{conf['ip']}/api/users").
          with { |req| req.body == "user=%7B%22user_name%22%3D%3E%22#{conf['username']}%22%2C+%22password%22%3D%3E%22#{conf['password']}%22%2C+%22password_confirmantion%22%3D%3E%22#{conf['password']}%22%7D" }
      end
    end
  end
end
