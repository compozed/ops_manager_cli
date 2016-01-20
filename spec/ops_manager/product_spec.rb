require 'spec_helper'
require 'ops_manager/product'

describe OpsManager::Product do
  let(:product){ described_class.new(name, version, filepath) }
  let(:name){  'example-product' }
  let(:filepath) { 'example-product-1.6.2.pivotal' }
  let(:version){ '1.6.2.0' }


  describe "#initialize" do
    %w(name version filepath).each do |attr|
      it "sets the #{attr}" do
        expect(product.send(attr)).to eq(send(attr))
      end
    end
  end

  describe "Product.exists?" do
    describe 'when product exists' do
      it "should be true" do
        VCR.use_cassette 'find existent product' do
          expect(OpsManager::Product.exists?('cf','1.5.4.0')).to eq(true)
        end
      end
    end

    describe 'when product does not exists' do
      it "should be false" do
        VCR.use_cassette 'find non existent product' do
          expect(OpsManager::Product.exists?('cf','1.6')).to eq(false)
        end
      end
    end
  end

  describe "#upgrade" do
    it 'Should perform in the right order' do
      %i( upload perform_upgrade).each do |m|
        expect(product).to receive(m).ordered
      end
      product.upgrade
    end
  end

  describe "#perform_upgrade" do
  end

  describe '#delete_unused_products' do
    it 'deletes product tile successfully' do
      VCR.use_cassette 'deleting product' do
        product.upload
        expect do
          product.delete_unused_products
        end.to change{ OpsManager::Product.exists?(name, version ) }.to(false)
      end
    end
  end

  describe "#upload" do
    before do
      `rm #{filepath} ; cp ../fixtures/#{filepath} .`
    end

    describe "when product does not exist" do
      it "uploads product tile successfully" do
        allow(product).to receive(:`) if OpsManager.get_conf(:target) == '1.2.3.4'
        VCR.use_cassette 'uploading product' do
          product.delete_unused_products
          expect do
            product.upload
          end.to change{ OpsManager::Product.exists?(name, version ) }.to(true)
        end
      end
    end

    describe "when product already exists" do
      before do
        allow(described_class).to receive(:exists?).and_return(true)
      end

      it 'should skip product upload' do
        expect(product).not_to receive(:`)
        product.upload
      end
    end
  end

  describe "deploy" do
    describe "when is the first time that it gets deployed" do
      it "upload new product"
      it "should add new product" #check on this
      it "upload updated installation settings"
      it "perform deployment"
    end

    describe "when desired version is newer than actual version" do
      let(:version){ '1.6.3.0' }

      before { product.perform_deploy }

      xit 'should perform an upgrade' do
        expect_any_instance_of(OpsManager::Product).to receive(:upgrade)
        product.deploy
      end
    end

    describe "when desired version equals actual version" do
      xit 'should not perform an upgrade' do
        expect_any_instance_of(OpsManager::Product).not_to receive(:upgrade)
      end
    end
  end
end
