require 'spec_helper'
require 'ops_manager/product'

describe OpsManager::Product do
  let(:product){ described_class.new('product_deployment.yml', force) }
  let(:force){ false }
  let(:product_exists?){ false }
  let(:name){ 'example-product' }
  let(:filepath) { 'example-product-1.6.1.pivotal' }
  let(:guid) { 'example-product-abc123' }
  let(:installation_settings_file){ '../fixtures/installation_settings.json' }
  let(:version){ '1.6.2.0' }
  let(:current_version){ version }
  let(:product_installation){ OpsManager::ProductInstallation.new(guid, current_version, true) }
  let(:installation){ double.as_null_object }

  before do
    `rm #{filepath} ; cp ../fixtures/#{filepath} .`
    allow(product).to receive(:installation)
      .and_return(product_installation)
    allow(described_class).to receive(:exists?)
      .and_return(product_exists?)
    allow(OpsManager::Installation).to receive(:trigger!).and_return(installation)
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
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_products).and_return(products_response)
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

  describe "#deploy" do
    subject(:deploy){ product.deploy }

    before do
      allow(product).tap do |s|
        s.to receive(:upload)
        s.to receive(:upload_installation_settings)
        s.to receive(:get_installation_settings)
        s.to receive(:`)
      end

    end

    it 'performs a product upload' do
      expect(product).to receive(:upload)
      deploy
    end

    it 'should download current installation setting' do
      expect(product).to receive(:get_installation_settings).with({write_to: '/tmp/is.yml'})
      deploy
    end

    it 'should spruce merge current installation settings with product installation settings' do
      expect(product).to receive(:`).with("DEBUG=false spruce merge /tmp/is.yml #{installation_settings_file} > /tmp/new_is.yml")
      deploy
    end

    it 'should upload new installation settings' do
      expect(product).to receive(:upload_installation_settings).with('/tmp/new_is.yml')
      deploy
    end

    it 'should trigger installation' do
      expect(OpsManager::Installation).to receive(:trigger!)
      deploy
    end

    it 'should wait for installation' do
      expect(installation).to receive(:wait_for_result)
      deploy
    end
  end


  describe "#upgrade" do
        subject(:upgrade){ product.upgrade }

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
      end
    end

    describe "when current installation is prepared" do
      let(:installation_prepared){ true }

      it 'performs a product upload' do
        expect(product).to receive(:upload)
        upgrade
      end


      it 'should perform a version upgrade' do
        expect(product).to receive(:upgrade_product_installation)
          .with(guid, version)
        upgrade
      end

      it 'should trigger installation' do
        expect(OpsManager::Installation).to receive(:trigger!)
        upgrade
      end

      it 'should wait for installation' do
        expect(installation).to receive(:wait_for_result)
        upgrade
      end
    end

    describe "when previous installation is not prepared" do
      let(:installation_prepared){ false }

      it 'Should skip upgrade' do
        expect(product).not_to receive(:upload_product)
        expect(product).not_to receive(:upgrade_product_installation)
        upgrade
      end
    end

  end


  describe "#run" do
    subject(:run){ product.run }

    before do
      allow(OpsManager).to receive(:target_and_login)
      allow_any_instance_of(OpsManager::Product).to receive(:deploy)
      allow(product).to receive(:import_stemcell)
    end

    it 'should target_and_login' do
      expect(OpsManager).to receive(:target_and_login)
      run
    end

    it 'should provision stemcell' do
      expect(product).to receive(:import_stemcell).with('stemcell.tgz')
      run
    end

    it 'should execute a product deploy' do
      expect_any_instance_of(OpsManager::Product).to receive(:deploy)
      run
    end


    describe "when installation is nil" do
      let(:product_installation){ nil }

      it "perform deployment" do
        expect(product).to receive(:deploy)
      run
      end
    end

    describe "when installation exists" do
      let(:version){ '1.6.2.0' }
      before do
        allow(product).to receive(:upgrade)
        allow(product).to receive(:deploy)
      end

      describe "when version is newer than the current one" do
        let(:current_version){ '1.5.2.0' }

        it "perform upgrade" do
          expect(product).to receive(:upgrade)
      run
        end
      end

      describe "when version match current one" do
        let(:current_version){ version }

        it "perform upgrade" do
          expect(product).to receive(:deploy)
          run
        end
      end
    end

    describe "when forced deployment" do
      it "perform deployment" do
        expect(product).to receive(:deploy)
        run
      end
    end
  end

  describe "upload" do
    describe "when product does not exist" do
      let(:product_exists?){ false }

      it "uploads product" do
        expect(product).to receive(:upload_product)
        product.upload
      end
    end

    describe "when product already exists" do
      let(:product_exists?){ true }

      it 'should skip product upload' do
        expect(product).not_to receive(:upload_product)
        product.upload
      end
    end
  end
end
