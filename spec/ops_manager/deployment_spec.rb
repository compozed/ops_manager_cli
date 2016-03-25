require 'spec_helper'
require 'yaml'
require "ops_manager/deployment"

describe OpsManager::Deployment do
  let(:deployment){ described_class.new(name, desired_version) }
  let(:name){ 'ops-manager' }
  let(:desired_version){'1.5.5.0'}
  let(:installation_settings){ double('installation_settings').as_null_object }
  let(:pivnet_api){ double('pivnet_api').as_null_object }

  before do
    allow(OpsManager::InstallationSettings).to receive(:new).and_return(installation_settings)
    allow(OpsManager::PivnetApi).to receive(:new).and_return(pivnet_api)
  end

  describe 'new' do
    %w{ name desired_version}.each do |p|
      it "should set #{p}" do
        expect(deployment.send(p)).to eq(send(p))
      end
    end
  end

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
    before do
      %i( get_installation_assets get_installation_settings
         stop_current_vm deploy upload_installation_assets
         import_stemcell ).each do |m|
        allow(deployment).to receive(m)
      end

    end

    it 'Should perform in the right order' do
      %i( get_installation_assets get_installation_settings
         stop_current_vm deploy upload_installation_assets ).each do |m|
           expect(deployment).to receive(m).ordered
         end
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

  describe 'create_first_user' do
    it 'should try to create user until success' do
      VCR.use_cassette 'create first user', record: :none do
        expect(deployment).to receive(:create_user).twice.and_call_original
        deployment.create_first_user
      end
    end
  end
end
