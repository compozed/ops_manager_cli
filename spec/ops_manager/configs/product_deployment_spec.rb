require 'spec_helper'
require 'ops_manager/configs/product_deployment'

describe OpsManager::Configs::ProductDeployment do
  let(:product_deployment_config){ described_class.new(config) }
  let(:stemcell){ 'stemcell.tgz' }
  let(:config) do
    {
      'name' => 'example-product',
      'desired_version'  => '1.6.2.0',
      'stemcell' => stemcell
    }
  end

  it "should not error when configs are correct" do
    expect do
      product_deployment_config
    end.not_to raise_error
  end

  %w{ name desired_version }.each do |attr|
    it "should require #{attr}" do
      config.delete(attr)
      expect do
        product_deployment_config
      end.to raise_error
    end
  end

  describe '#stemcell' do
    describe 'when stemcell is a regex' do
      let(:stemcell){ '*.tgz' }

      it 'should return first mathing path' do
        expect(product_deployment_config.stemcell).to eq('stemcell.tgz')
      end
    end
  end
end
