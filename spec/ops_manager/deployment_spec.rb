require 'spec_helper'
require 'yaml'
require "ops_manager/deployment"

describe OpsManager::Deployment do
  let(:name){ 'ops-manager' }
  let(:desired_version){'1.5.5.0'}
  let(:deployment){ described_class.new(name, desired_version) }

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
end
