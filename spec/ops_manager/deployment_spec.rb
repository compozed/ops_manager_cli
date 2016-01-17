require 'spec_helper'
require 'yaml'
require "ops_manager/deployment"

describe OpsManager::Deployment do
  let(:name){ 'ops-manager' }
  let(:ip){ '1.2.3.4' }
  let(:version){'1.5.5.0'}
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:base_uri){ 'https://foo:bar@1.2.3.4' }

  let(:deployment){ described_class.new(name, version) }

  %w{ stop_current_vm deploy_vm }.each do |m|
    describe m do
      it 'should raise not implemented error'  do
        expect{ deployment.send(m) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe 'deploy' do
    it 'Should perform in the right order' do
      %i( deploy_vm create_first_user).each do |m|
        expect(deployment).to receive(m).ordered
      end
      deployment.deploy
    end
  end

  describe 'upgrade' do
    it 'Should perform in the right order' do
      %i( get_installation_assets get_installation_settings
         stop_current_vm deploy upload_installation_assets ).each do |m|
        expect(deployment).to receive(m).ordered
      end
      deployment.upgrade
    end
  end

  describe 'create_first_user' do
    it 'should try to create user until success' do
      VCR.use_cassette 'create first user', record: :none do
        expect(deployment).to receive(:create_user).twice.and_call_original
        deployment.create_first_user
      end
    end
  end

  describe 'get_installation_assets' do
    before{ `rm -r installation_assets.zip assets` }

    it 'should download successfully' do
      VCR.use_cassette 'installation assets download' do
        deployment.get_installation_assets
        expect(File).to exist("installation_assets.zip" )
        `unzip installation_assets.zip -d assets`
        expect(File).to exist("assets/deployments/bosh-deployments.yml")
        expect(File).to exist("assets/installation.yml")
        expect(File).to exist("assets/metadata/microbosh.yml")
      end
    end
  end

  describe 'get_installation_settings' do
    before{ `rm installation_settings.zip` }

    it 'should download successfully' do
      expected_json = JSON.parse(File.read('../fixtures/pretty_installation_settings.json'))

      VCR.use_cassette 'installation settings download' do
        deployment.get_installation_settings
        expect( JSON.parse(File.read('installation_settings.json'))).to eq(expected_json)
      end
    end
  end

  describe 'upload_installation_assets' do
    before do
      `rm installation_assets.zip`
      `cp ../fixtures/installation_assets.zip .`
    end

    it 'should upload successfully' do
      VCR.use_cassette 'uploading assets' do
        expect do
          deployment.upload_installation_assets
        end.to change{ deployment.get_installation_assets.code.to_i }.from(500).to(200)
      end
    end
  end

  describe 'new' do
    %w{ name version ip username password}.each do |p|
      it "should set #{p}" do
        expect(deployment.send(p)).to eq(send(p))
      end
    end
  end

  describe 'current_version' do
    describe 'when there is no ops manager' do
      before { allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ETIMEDOUT) }

      it 'should be nil' do
        expect(deployment.current_version).to be_nil
      end
    end
  end

  describe '#create_user' do
    before do
      stub_request(:post, uri).
        with(:body => body,
             :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})
    end

    describe 'when version 1.5.x' do
      let(:version){ '1.5.5.0' }
      let(:body){ "user[user_name]=foo&user[password]=bar&user[password_confirmantion]=bar"}
      let(:uri){ "#{base_uri}/api/users" }

      it "should successfully create first user" do
        VCR.turned_off do
          deployment.create_user
        end
      end
    end

    describe 'when version 1.6.x' do
      let(:version){ '1.6.4' }
      let(:uri){ "#{base_uri}/api/setup" }
      let(:body){ "setup[user_name]=foo&setup[password]=bar&setup[password_confirmantion]=bar&setup[eula_accepted]=true" }

      it "should successfully setup first user" do
        VCR.turned_off do
          deployment.create_user
        end
      end
    end
  end
end
