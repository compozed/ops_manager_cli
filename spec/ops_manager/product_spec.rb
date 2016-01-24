require 'spec_helper'
require 'ops_manager/product'

describe OpsManager::Product do
  let(:product){ described_class.new(name) }
  let(:name){ 'example-product' }
  let(:filepath) { 'example-product-1.6.1.pivotal' }
  let(:version){ '1.6.2.0' }
  let(:guid) { 'example-product-abc123' }
  let(:product_installation){ OpsManager::ProductInstallation.new(guid, version) }

  before do
    `rm #{filepath} ; cp ../fixtures/#{filepath} .`
  end

  describe "#initialize" do
    %w(name).each do |attr|
      it "sets the #{attr}" do
        expect(product.send(attr)).to eq(send(attr))
      end
    end
  end

  describe "#installation" do
    it "should look for its ProductInstallation" do
      expect(OpsManager::ProductInstallation).to receive(:find).with(name)
      product.installation
    end
  end

  describe "#available_versions"

  describe "Product.exists?" do
    let(:products_response){ double(body: [{'name' => 'cf', 'product_version' => '1'}].to_json )}

    before { allow_any_instance_of(OpsManager::Product).to receive(:get_products).and_return(products_response) }

    describe 'when product exists' do
      it "should be true" do
        expect(OpsManager::Product.exists?('cf','1')).to eq(true)
      end
    end

    describe 'when product does not exists' do
      it "should be false" do
        expect(OpsManager::Product.exists?('cf','2')).to eq(false)
      end
    end
  end

  describe "#upgrade" do
    let(:product_installation){ OpsManager::ProductInstallation.new(guid, '1.6.0.0') }
    let(:filepath) { 'example-product-1.6.2.pivotal' }

    describe "when product does not exist" do
      before do
        allow(described_class).to receive(:exists?).and_return(false)
      end

      it "uploads product" do
        allow(product).to receive(:installation).and_return(product_installation)
        allow(product).to receive(:upgrade_product_installation).with(guid, version)
        allow(product).to receive(:trigger_installation)
        expect(product).to receive(:upload_product)
        product.upgrade(version, filepath)
      end
    end

    describe "when product already exists" do
      before do
        allow(described_class).to receive(:exists?).and_return(true)
      end

      it 'should skip product upload' do
        allow(product).to receive(:installation).and_return(product_installation)
        allow(product).to receive(:upgrade_product_installation).with(guid, version)
        allow(product).to receive(:trigger_installation)
        expect(product).not_to receive(:upload_product)
        product.upgrade(version, filepath)
      end
    end

    it 'should perform a version upgrade' do
      allow(product).to receive(:upload)
      allow(product).to receive(:installation).and_return(product_installation)
      allow(product).to receive(:trigger_installation)
      expect(product).to receive(:upgrade_product_installation).with(guid, version)
      product.upgrade(version, filepath)
    end

    it 'should trigger installation' do
      allow(product).to receive(:upload)
      allow(product).to receive(:installation).and_return(product_installation)
      allow(product).to receive(:upgrade_product_installation)
      expect(product).to receive(:trigger_installation)
      product.upgrade(version, filepath)
    end
  end


  describe "#deploy" do
    describe "when is the first time that it gets deployed" do
      it "upload new product"
      it "should add new product" #check on this
      it "upload updated installation settings"
      it "perform deployment"
    end

    describe "when desired version is newer than actual version" do
      let(:version){ '1.6.3.0' }

      before { product.perform_deploy }

      it 'should perform an upgrade' do
        expect_any_instance_of(OpsManager::Product).to receive(:upgrade).with(version, filepath)
        product.deploy(version, filepath)
      end
    end

    describe "when desired version equals actual version" do
      xit 'should not perform an upgrade' do
        expect_any_instance_of(OpsManager::Product).not_to receive(:upgrade)
      end
    end
  end
end
