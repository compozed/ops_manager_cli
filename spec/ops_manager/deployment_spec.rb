require 'spec_helper'
require 'yaml'
require "ops_manager/deployment"

describe OpsManager::Deployment do
  let(:name){ 'ops-manager' }
  let(:version){'1.5.5.0'}

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
    %w{ name version }.each do |p|
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
end
