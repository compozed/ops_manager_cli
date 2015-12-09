require 'spec_helper'

describe OpsManagerDeployer::Vsphere do
  let(:vsphere){ described_class.new }

  it 'should inherit from cloud' do
    expect(described_class).to be < OpsManagerDeployer::Cloud
  end
end
