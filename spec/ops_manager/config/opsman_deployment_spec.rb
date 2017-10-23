require 'spec_helper'
require 'ops_manager/config/opsman_deployment'

describe OpsManager::Config::OpsmanDeployment do
  let(:opsman_deployment_config){ described_class.new(config) }
  let(:config) do
    {
      'name' => 'example-product',
      'provider' => 'vsphere',
      'desired_version'  => '1.4.11.0',
      'username' => 'foo',
      'password' => 'bar',
      'ova_path' => "*.ova",
      'ip' => '1.2.3.4',
      'pivnet_token' => 'abc123',
      'opts' => {
        'vcenter' => {
          'host' => '1.2.3.4',
          'username' => 'foo',
          'password' => 'bar',
        }
      }
    }
  end

  it 'should symbolize recursively the configs' do
    expect(opsman_deployment_config[:opts][:vcenter][:host]).to eq('1.2.3.4')
  end

  it 'should not error when configs are correct' do
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

  %w{ ova_path }.each do |attr|
    it "should expand path for #{attr}" do
      expect(described_class).to receive(:expand_path_for!).with(attr)
      product_deployment_config
    end
  end
end
