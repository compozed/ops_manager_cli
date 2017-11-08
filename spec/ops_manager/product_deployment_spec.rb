require 'spec_helper'
require 'ops_manager/product_deployment'

describe OpsManager::ProductDeployment do
  let(:product_deployment){ described_class.new('product_deployment.yml', force) }
  let(:force){ false }
  let(:name){ 'example-product' }
  let(:target){'1.2.3.4'}
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:filepath) { 'tile.pivotal' }
  let(:guid) { 'example-product-abc123' }
  let(:installation_settings_file){ '../fixtures/installation_settings.json' }
  let(:desired_version){ '1.6.2.0' }
  let(:current_version){ '1.6.2.0' }
  let(:errands){ %w{ errand1 errand2} }
  let!(:installation_runner){ object_double(OpsManager::InstallationRunner.new).as_null_object }
  let(:product_installation){ OpsManager::ProductInstallation.new(guid, current_version, true) }
  let(:installation){ double.as_null_object }
  let(:config) do
    {
      target: target,
      username: username,
      password: password,
      name: name,
      desired_version: desired_version,
      filepath: filepath,
      stemcell: 'stemcell.tgz',
      installation_settings_file: installation_settings_file
    }
  end


  before do
    allow(product_deployment).tap do |pd|
      pd.to receive(:config).and_return(config)
    end
    allow(OpsManager::ProductInstallation).to receive(:find).and_return(product_installation)
    allow(OpsManager::InstallationRunner).to receive(:trigger!).and_return(installation)
  end

  describe "#installation" do
    it "should look for its ProductInstallation" do
      expect(OpsManager::ProductInstallation).to receive(:find).with(name)
      product_deployment.installation
    end
  end

  describe "#merge_product_installation_settings" do
    subject(:merge_product_installation_settings){ product_deployment.merge_product_installation_settings }

    before do
      allow(product_deployment).tap do |s|
        s.to receive(:get_installation_settings)
        s.to receive(:`)
        s.to receive(:upload_installation_settings)
      end
    end

    it 'should download current installation setting' do
      expect(product_deployment).to receive(:get_installation_settings).with({write_to: '/tmp/is.yml'})
      merge_product_installation_settings
    end

    it 'should spruce merge current installation settings with product installation settings' do
      expect(product_deployment).to receive(:`).with("DEBUG=false DEFAULT_ARRAY_MERGE_KEY=identifier spruce merge /tmp/is.yml #{installation_settings_file} > /tmp/new_is.yml")
      merge_product_installation_settings
    end

    it 'should upload new installation settings' do
      expect(product_deployment).to receive(:upload_installation_settings).with('/tmp/new_is.yml')
      merge_product_installation_settings
    end
  end

  describe "@exists?" do
    let(:products_response){ double(body: [{'name' => 'cf', 'product_version' => '1'}].to_json )}

    before do
      allow(described_class).to receive(:exists?)
        .and_call_original
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_available_products).and_return(products_response)
    end

    describe 'when product exists' do
      it "should be true" do
        expect(OpsManager::ProductDeployment.exists?('cf','1')).to eq(true)
      end
    end

    describe 'when product does not exists' do
      it "should be false" do
        expect(OpsManager::ProductDeployment.exists?('cf','2')).to eq(false)
      end
    end
  end

  describe '#add_to_installation' do
    subject(:add_to_installation){ product_deployment.add_to_installation }

    before { allow(product_deployment).to receive(:installation).and_return(installation) }

    describe 'when installation exists' do
      let(:installation){ double.as_null_object }

      it 'should not perform the add_staged_product' do
        expect_any_instance_of(OpsManager::Api::Opsman).not_to receive(:add_staged_products)
        add_to_installation
      end
    end

    describe 'when installation does not exists' do
      let(:installation){ nil }

      it 'should perform the add_staged_product' do
        expect_any_instance_of(OpsManager::Api::Opsman).to receive(:add_staged_products)
        add_to_installation
      end
    end
  end

  describe "#deploy" do
    subject(:deploy){ product_deployment.deploy }

    before do
      allow(product_deployment).tap do |s|
        s.to receive(:upload)
        s.to receive(:add_to_installation)
        s.to receive(:merge_product_installation_settings)
      end
    end

    it 'performs a product_deployment upload' do
      expect(product_deployment).to receive(:upload)
      deploy
    end

    it 'should merge product installation settings' do
      expect(product_deployment).to receive(:merge_product_installation_settings)
      deploy
    end

    it 'should add product to installation' do
      expect(product_deployment).to receive(:add_to_installation)
      deploy
    end


    it 'should wait for installation' do
      expect(installation).to receive(:wait_for_result)
      deploy
    end
  end


  describe "#upgrade" do
    subject(:upgrade){ product_deployment.upgrade }
    let(:product_installation) do
      OpsManager::ProductInstallation.new(guid, '1.6.0.0', true)
    end

    let(:filepath) { 'tile.pivotal' }
    let(:product_exists?){ true }
    before do
      allow(product_installation).to receive(:prepared?)
        .and_return(installation_prepared)
      allow(product_deployment).tap do |s|
        s.to receive(:upgrade_product_installation).with(guid, desired_version)
        s.to receive(:upload)
        s.to receive(:merge_product_installation_settings)
      end
    end

    describe "when current installation is prepared" do
      let(:installation_prepared){ true }

      it 'performs a product upload' do
        expect(product_deployment).to receive(:upload)
        upgrade
      end

      it 'should merge product installation settings' do
        expect(product_deployment).to receive(:merge_product_installation_settings)
        upgrade
      end

      it 'should perform a desired_version upgrade' do
        expect(product_deployment).to receive(:upgrade_product_installation)
          .with(guid, desired_version)
        upgrade
      end

      it 'should trigger installation' do
        expect(OpsManager::InstallationRunner).to receive(:trigger!)
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
        expect(product_deployment).not_to receive(:upload)
        expect(product_deployment).not_to receive(:upgrade_product_installation)
        upgrade
      end
    end

  end

  describe '#upload' do
    subject(:upload){ product_deployment.upload }

    before { allow(described_class).to receive(:exists?).and_return(product_exists?) }

    describe 'when product already present in ops man' do
      let(:product_exists?){ true }

      it 'Should skip product upload' do
        expect(product_deployment).not_to receive(:upload_product)
        upload
      end
    end

    describe 'when tile path is not present(config.filepath)' do
      let(:product_exists?){ false }
      let(:filepath) { nil }

      it 'Should skip product upload' do
        expect(product_deployment).not_to receive(:upload_product)
        upload
      end
    end

    describe 'when product is not present' do
      let(:product_exists?){ false }

      it 'Should upload product ' do
        expect(product_deployment).to receive(:upload_product)
        upload
      end
    end
  end

  describe "#run" do
    subject(:run){ product_deployment.run }

    before do
      allow(OpsManager).to receive(:target_and_login)
      allow(product_deployment).to receive(:deploy)
      allow(product_deployment).to receive(:import_stemcell)
    end

    it 'should target_and_login' do
      expect(OpsManager).to receive(:target_and_login)
      run
    end

    it 'should provision stemcell' do
      expect(product_deployment).to receive(:import_stemcell).with('stemcell.tgz')
      run
    end

    it 'should execute a product deploy' do
      expect(product_deployment).to receive(:deploy)
      run
    end

    describe "when installation is nil" do
      let(:product_installation){ nil }

      it "perform deployment" do
        expect(product_deployment).to receive(:deploy)
        run
      end
    end

    describe "when installation exists" do
      let(:desired_version){ '1.4.10-build.1' }
      before do
        allow(product_deployment).to receive(:upgrade)
        allow(product_deployment).to receive(:deploy)
      end

      describe "when version is newer than the current one" do
        let(:current_version){ '1.4.9-build.7' }

        it "perform upgrade" do
          expect(product_deployment).to receive(:upgrade)
          run
        end
      end

      describe "when version match current one" do
        let(:current_version){ desired_version }

        it "perform upgrade" do
          expect(product_deployment).to receive(:deploy)
          run
        end
      end
    end

    describe "when forced deployment" do
      it "perform deployment" do
        expect(product_deployment).to receive(:deploy)
        run
      end
    end
  end
end
