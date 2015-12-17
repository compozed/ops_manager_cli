require 'spec_helper'
require 'yaml'
require "ops_manager_deployer/deployment"

describe OpsManagerDeployer::Deployment do
  let(:deployment){ described_class.new }

  %w{ deploy downgrade upgrade }.each do |m|
    describe m do
      it 'should raise not implemented error'  do
        expect{ deployment.send(m) }.to raise_error(NotImplementedError)
      end
    end
  end
end
