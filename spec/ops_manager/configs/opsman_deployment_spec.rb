require 'spec_helper'
require 'ops_manager/configs/opsman_deployment'

describe OpsManager::Configs::OpsmanDeployment do
  let(:opsman_deployment_config){ described_class.new(config) }
  let(:config) do
    {
      'name' => 'example-product',
      'version'  => '1.4.11.0',
      'provider' => 'vsphere',
      'ip' => '1.2.3.4',
      'username' => 'foo',
      'password' => 'bar',
      'pivnet_token' => 'abc123',
      'opts' => {}
    }
  end

  it "should not error when configs are correct" do
      expect do
        opsman_deployment_config
      end.not_to raise_error
    end

  %w{ name provider username password pivnet_token version target ops }.each do |attr|
    it "should require #{attr}" do
      config.delete(attr)
      expect do
        product_deployment_config
      end.to raise_error
    end
  end
end
