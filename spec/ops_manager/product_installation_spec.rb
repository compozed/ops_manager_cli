require 'spec_helper'
require 'ops_manager/product_installation'

describe OpsManager::ProductInstallation do
  describe '@find' do
    describe "when the product installation does not exists" do
      let(:name){ 'imaginary-product' }

      it "should be nil" do
        VCR.use_cassette 'product not installed' do
          expect(described_class.find(name)).to be_nil
        end
      end
    end

    describe "when the product installation exists" do
      let(:name){ 'p-bosh' }

      subject(:installation) do
        installation = nil
        VCR.use_cassette 'product installed' do
          installation = described_class.find(name)
        end
        installation
      end

      it "should return guid" do
        expect(installation.guid).to eq('microbosh-9b6fc5940334026515a3')
      end

      it "should return version" do
        expect(installation.version).to eq('1.6.6.0')
      end
    end
  end
end
