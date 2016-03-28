require 'spec_helper'
require 'ops_manager/product_installation'

describe OpsManager::ProductInstallation do
  let(:name){ 'p-bosh' }
  let(:guid) { 'example-product-abc123' }
  let(:version){ '1.6.2.0' }
  let(:product_installation){ described_class.new(guid, version, true) }


  describe '@find' do
    subject(:installation) do
      VCR.use_cassette 'product installed' do
        described_class.find(name)
      end
    end

    it "should return guid" do
      expect(installation.guid).to eq('microbosh-9b6fc5940334026515a3')
    end

    it "should return version" do
      expect(installation.version).to eq('1.6.6.0')
    end

    describe "when the product installation does not exists" do
      let(:name){ 'imaginary-product' }

      subject(:installation) do
        VCR.use_cassette 'product not installed' do
          described_class.find(name)
        end
      end

      it "should be nil" do
        expect(installation).to be_nil
      end
    end


    describe "when the product installation exists" do

      subject(:installation) do
        VCR.use_cassette 'product installed' do
          described_class.find(name)
        end
      end

      it "should fetch installation_settings#prepared entry" do
        expect(installation).to be_prepared
      end
    end

    describe "when the product installation exists but is not prepared" do

      subject(:installation) do
        VCR.use_cassette 'product installed not prepared' do
          described_class.find(name)
        end
      end

      it "should be prepared" do
        expect(installation).not_to be_prepared
      end
    end
  end
end
