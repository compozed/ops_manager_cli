require 'spec_helper'
require "ops_manager/deployment"
require 'yaml'

describe OpsManager::Deployment do
  let(:deployment){ described_class.new('ops_manager_deployment.yml') }
  let(:target){'1.2.3.4'}
  let(:current_version){ '1.4.2.0' }
  let(:desired_version){'1.5.5.0'}
  let(:pivnet_api){ double('pivnet_api').as_null_object }
  let(:username){ 'foo' }
  let(:password){ 'foo' }
  let(:pivnet_token){ 'asd123' }
  let(:installation){ double.as_null_object }
  let(:installation_settings){ double('installation_settings').as_null_object }
  let(:target){ '1.2.3.4' }
  let(:config) do
    double('config',
           desired_version: desired_version,
           ip: target,
           password: password,
           username: username,
           pivnet_token: pivnet_token)
  end

  before do
    OpsManager.set_conf(:target, ENV['TARGET'] || target)
    OpsManager.set_conf(:username, ENV['USERNAME'] || 'foo')
    OpsManager.set_conf(:password, ENV['PASSWORD'] || 'bar')

    allow(OpsManager::InstallationSettings).to receive(:new).and_return(installation_settings)
    allow(OpsManager::Api::Pivnet).to receive(:new).and_return(pivnet_api)
    allow(OpsManager::Installation).to receive(:trigger!).and_return(installation)

    allow(deployment).to receive(:get_current_version).and_return(current_version)
  end

  %w{ stop_current_vm deploy_vm }.each do |m|
    describe m do
      it 'should raise not implemented error' do
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
    before do
      %i( get_installation_assets get_installation_settings
         stop_current_vm deploy upload_installation_assets
         import_stemcell ).each do |m|
           allow(deployment).to receive(m)
         end
    end

    it 'Should perform in the right order' do
      %i( get_installation_assets get_installation_settings
         stop_current_vm deploy provision_missing_stemcells
         upload_installation_assets ).each do |m|
           expect(deployment).to receive(m).ordered
         end
         deployment.upgrade
    end

    it 'should trigger installation' do
      expect(OpsManager::Installation).to receive(:trigger!)
      deployment.upgrade
    end

    it 'should wait for installation' do
      expect(installation).to receive(:wait_for_result)
      deployment.upgrade
    end

    describe 'when provisioning missing stemcells' do
      let(:stemcell_version){ "3146.10" }
      let(:other_stemcell_version){ "3146.11" }
      before do
        allow(installation_settings).to receive(:stemcells).and_return(
          [
            {
              file: 'stemcell-1.tgz',
              version: stemcell_version
            },
            {
              file: 'stemcell-2.tgz',
              version: other_stemcell_version
            }
          ]
        )
      end

      it 'should download missing stemcells' do
        expect(pivnet_api).to receive(:download_stemcell).with(stemcell_version, 'stemcell-1.tgz', /vsphere/)
        expect(pivnet_api).to receive(:download_stemcell).with(other_stemcell_version, 'stemcell-2.tgz', /vsphere/)
        deployment.upgrade
      end

      it 'should upload missing stemcells' do
        expect(deployment).to receive(:import_stemcell).with('stemcell-1.tgz')
        expect(deployment).to receive(:import_stemcell).with('stemcell-2.tgz')
        deployment.upgrade
      end
    end
  end

  describe 'run' do

    before do
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_current_version).and_return(current_version)
      allow(deployment).tap do |d|
        d.to receive(:config).and_return(config)
        d.to receive(:deploy)
        d.to receive(:upgrade)
      end
    end
    subject(:run){ deployment.run }

    describe 'when no ops-manager has been deployed' do
      let(:current_version){ '' }

      it 'performs a deployment' do
        expect(deployment).to receive(:deploy)
        expect do
          run
        end.to output(/No OpsManager deployed at #{target}. Deploying .../).to_stdout
      end

      it 'does not performs an upgrade' do
        expect(deployment).to_not receive(:upgrade)
        expect do
          run
        end.to output(/No OpsManager deployed at #{target}. Deploying .../).to_stdout
      end
    end

    describe 'when ops-manager has been deployed and current and desired version match' do
      let(:desired_version){ current_version }

      it 'does not performs a deployment' do
        expect(deployment).to_not receive(:deploy)
        expect do
          run
        end.to output(/OpsManager at #{target} version is already #{current_version}. Skiping .../).to_stdout
      end

      it 'does not performs an upgrade' do
        expect(deployment).to_not receive(:upgrade)
        expect do
          run
        end.to output(/OpsManager at #{target} version is already #{current_version}. Skiping .../).to_stdout
      end
    end

    describe 'when current version is older than desired version' do
      let(:current_version){  '1.4.2.0' }
      let(:desired_version){  '1.4.11.0' }

      it 'performs an upgrade' do
        expect(deployment).to receive(:upgrade)
        expect do
          run
        end.to output(/OpsManager at #{target} version is #{current_version}. Upgrading to #{desired_version}.../).to_stdout
      end

      it 'does not performs a deployment' do
        expect(deployment).to_not receive(:deploy)
        expect do
          run
        end.to output(/OpsManager at #{target} version is #{current_version}. Upgrading to #{desired_version}.../).to_stdout
      end
    end
  end

  describe 'create_first_user' do
    describe 'when first try fails' do
      let(:error_response){ double({ code: 502 }) }
      let(:success_response){ double({ code: 200 }) }
      before { allow(deployment).to receive(:create_user).and_return(error_response, success_response) }

      it 'should retry until success' do
          expect(deployment).to receive(:create_user).twice
          deployment.create_first_user
      end
    end
  end
end
