require 'spec_helper'
require 'ops_manager/configs/opsman_deployment'

describe OpsManager::Configs::OpsmanDeployment do
  let(:opsman_deployment_config){ described_class.new(config) }
  let(:config) do
    {
      'name' => 'example-product',
      'provider' => 'vsphere',
      'desired_version'  => '1.4.11.0',
      'username' => 'foo',
      'password' => 'bar',
      'ip' => '1.2.3.4',
      'pivnet_token' => 'abc123',
      'opts' => {}
    }
  end

  it "should not error when configs are correct" do
      expect do
        opsman_deployment_config
      end.not_to raise_error
    end

  %w{ name provider desired_version username password ip pivnet_token ops }.each do |attr|
    it "should require #{attr}" do
      config.delete(attr)
      expect do
        product_deployment_config
      end.to raise_error
    end
  end
end
