require 'spec_helper'
require "ops_manager/deployment"
require 'yaml'

describe OpsManager::Deployment do
  let(:deployment){ described_class.new('config_file_path') }
  let(:current_version){  '1.4.2.0' }
  let(:desired_version){  '1.4.2.0' }
  let(:name){ 'ops-manager' }
  let(:username){ 'foo' }
  let(:password){ 'foo' }
  let(:pivnet_token){ 'asd123' }
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
    allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_current_version).and_return(current_version)
    allow(deployment).tap do |d|
      d.to receive(:config).and_return(config)
      d.to receive(:deploy)
      d.to receive(:upgrade)
    end
  end

  describe 'run' do
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
end
