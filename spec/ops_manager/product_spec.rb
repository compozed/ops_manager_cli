require 'spec_helper'
require 'ops_manager/product'

describe OpsManager::Product do
  let(:product){ described_class.new(name) }
  let(:product_exists?){ false }
  let(:name){ 'example-product' }
  let(:filepath) { 'example-product-1.6.1.pivotal' }
  let(:version){ '1.6.2.0' }
  let(:guid) { 'example-product-abc123' }
  let(:installation_settings_file){ '../fixtures/installation_settings.json' }
  let(:product_installation){ OpsManager::ProductInstallation.new(guid, version, true) }
    let(:installation_id){ 1234 }

  before do
    `rm #{filepath} ; cp ../fixtures/#{filepath} .`
    allow(product).to receive(:installation)
      .and_return(product_installation)
    allow(described_class).to receive(:exists?)
      .and_return(product_exists?)
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
      allow(product).to receive(:installation).and_call_original
      expect(OpsManager::ProductInstallation).to receive(:find).with(name)
      product.installation
    end
  end

  describe "Product.exists?" do
    let(:products_response){ double(body: [{'name' => 'cf', 'product_version' => '1'}].to_json )}

    before do
      allow(described_class).to receive(:exists?)
        .and_call_original
      allow_any_instance_of(OpsManager::Product).to receive(:get_products).and_return(products_response)
    end

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

  describe "#perform_new_deployment" do
    before do
      allow(product).tap do |s|
        s.to receive(:upload)
        s.to receive(:upload_installation_settings)
        s.to receive(:trigger_installation)
          .and_return(double(body: "{\"id\":\"#{installation_id}\"}"))
        s.to receive(:get_installation_settings)
        s.to receive(:wait_for_installation)
        s.to receive(:`)
      end
    end

    it 'performs a product upload' do
      expect(product).to receive(:upload).with(version, filepath)
      product.perform_new_deployment(version, filepath, installation_settings_file)
    end

    it 'should download current installation setting' do
      expect(product).to receive(:get_installation_settings).with({write_to: '/tmp/is.yml'})
      product.perform_new_deployment(version, filepath, installation_settings_file)
    end

    it 'should spruce merge current installation settings with product installation settings' do
      expect(product).to receive(:`).with("spruce merge #{installation_settings_file} /tmp/is.yml > /tmp/new_is.yml")
      product.perform_new_deployment(version, filepath, installation_settings_file)
    end

    it 'should upload new installation settings' do
      expect(product).to receive(:upload_installation_settings).with('/tmp/new_is.yml')
      product.perform_new_deployment(version, filepath,installation_settings_file)
    end

    it 'should trigger installation' do
      expect(product).to receive(:trigger_installation)
      product.perform_new_deployment(version, filepath,installation_settings_file)
    end

    it 'should wait for installation' do
      # allow(product).to receive(:trigger_installation)
      expect(product).to receive(:wait_for_installation).with(installation_id)
      product.perform_new_deployment(version, filepath,installation_settings_file)
    end
  end

  describe "#wait_for_installation" do
    let(:success){ double(body: "{\"status\":\"succeess\"}") }
    let(:running){ double(body: "{\"status\":\"running\"}") }

    it 'returns on success' do
      expect(product).to receive(:get_installation)
        .with(installation_id)
        .and_return( running, running, success)
      product.wait_for_installation(installation_id)
    end
  end

  describe "#perform_upgrade" do
    let(:product_installation) do
      OpsManager::ProductInstallation.new(guid, '1.6.0.0', true)
    end
    let(:filepath) { 'example-product-1.6.2.pivotal' }
    let(:product_exists?){ true }
    before do
      allow(product_installation).to receive(:prepared?)
        .and_return(installation_prepared)
      allow(product).tap do |s|
        s.to receive(:upgrade_product_installation).with(guid, version)
        s.to receive(:upload_product)
        s.to receive(:trigger_installation)
      end
    end

    describe "when current installation is prepared" do
      let(:installation_prepared){ true }

      it 'performs a product upload' do
        expect(product).to receive(:upload)
        product.perform_upgrade(version, filepath)
      end


      it 'should perform a version upgrade' do
        expect(product).to receive(:upgrade_product_installation)
          .with(guid, version)
        product.perform_upgrade(version, filepath)
      end

      it 'should trigger installation' do
        expect(product).to receive(:trigger_installation)
        product.perform_upgrade(version, filepath)
      end
    end

    describe "when previous installation is not prepared" do
      let(:installation_prepared){ false }
      it 'Should skip upgrade' do
        expect(product).not_to receive(:upload_product)
        expect(product).not_to receive(:upgrade_product_installation)
        expect(product).not_to receive(:trigger_installation)
        product.perform_upgrade(version, filepath)
      end
    end

  end


  describe "#deploy" do
    describe "when installation is nil" do
      let(:product_installation){ nil }

      it "perform deployment" do
        expect(product).to receive(:perform_new_deployment)
        product.deploy(version, filepath, installation_settings_file)
      end
    end

    describe "when installation exists" do
      it "perform upgrade" do
        expect(product).to receive(:perform_upgrade)
        product.deploy(version, filepath, installation_settings_file)
      end
    end

    describe "when forced deployment" do
      it "perform deployment" do
        expect(product).to receive(:perform_new_deployment)
        product.deploy(version, filepath, installation_settings_file, true)
      end
    end
  end

  describe "upload" do
    describe "when product does not exist" do
      let(:product_exists?){ false }

      it "uploads product" do
        expect(product).to receive(:upload_product)
        product.upload(version, filepath)
      end
    end

    describe "when product already exists" do
      let(:product_exists?){ true }

      it 'should skip product upload' do
        expect(product).not_to receive(:upload_product)
        product.upload(version, filepath)
      end
    end
  end
end
