require 'spec_helper'
require 'yaml'
require "ops_manager_deployer/deployment"

describe OpsManagerDeployer::Deployment do
  let(:name){ 'ops-manager' }
  let(:ip){ '1.2.3.4' }
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:deployment){ described_class.new(name, ip, username, password) }

  %w{ deploy downgrade upgrade }.each do |m|
    describe m do
      it 'should raise not implemented error'  do
        expect{ deployment.send(m) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe 'new' do
    %w{ name ip username password }.each do |p|
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
