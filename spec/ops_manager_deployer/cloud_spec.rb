require 'spec_helper'
require 'yaml'
require "ops_manager_deployer/cloud"

describe OpsManagerDeployer::Cloud do
  let(:cloud){ described_class.new }

  %w{ deploy ommit upgrade }.each do |m|
    describe m do
      it 'should raise not implemented error'  do
        expect{ cloud.send(m) }.to raise_error(NotImplementedError)
      end
    end
  end
end
