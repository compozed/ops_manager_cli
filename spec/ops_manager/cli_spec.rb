require "spec_helper"

describe OpsManager::Cli do
  let(:cli){ described_class }

  describe "target" do
    let(:args) { %w(target 1.2.3.4) }

    it "should call OpsManager.set_target IP" do
      expect(OpsManager).to receive(:set_target).with('1.2.3.4')
      cli.run(`pwd`, args)
    end
  end

  describe "login" do
    let(:args) { %w(login foo bar) }

    it "should call OpsManager.login foo bar" do
      expect(OpsManager).to receive(:login).with('foo', 'bar')
      cli.run(`pwd`, args)
    end
  end

  # ./ops_manager deploy -c conf.yml
  describe "deploy" do
    let(:args) { %w(deploy) }

    it "should call ops_manager.deploy" do
      expect(OpsManager::Deployment).to receive(:new).and_call_original
      expect_any_instance_of(OpsManager::Deployment).to receive(:run)
      cli.run(`pwd`, args)
    end
  end

  describe "deployment" do
    let(:args) { %w(deployment ops_manager_deployment.yml) }

    it "should call OpsManager.deployment= with path to config file" do
      expect(OpsManager).to receive(:deployment=).with('ops_manager_deployment.yml')
      cli.run(`pwd`, args)
    end
  end


  # ./ops_manager deploy-product -c conf.yml
  describe "deploy-product" do
    let(:args) { "deploy-product #{'--force' if force} product.yml".split(" ") }

    before do
      expect(OpsManager::ProductDeployment).to receive(:new).with('product.yml', force).and_call_original
    end

    describe 'when no --force provided' do
      let(:force){ nil }

      it "should call ops_manager.deploy_product" do
        expect_any_instance_of(OpsManager::ProductDeployment).to receive(:run)
        cli.run(`pwd`, args)
      end
    end

    describe "when --force provided" do
      let(:force){ true }

      it "should call ops_manager.deploy_product with force" do
        expect_any_instance_of(OpsManager::ProductDeployment).to receive(:run)
        cli.run(`pwd`, args)
      end
    end
  end

  describe "ssh" do
    let(:args) { %w(ssh) }

    before do
      allow(OpsManager).to receive(:target).and_return('1.2.3.4')
    end

    it "should ssh to target with the ubuntu user" do
      expect_any_instance_of(OpsManager::Cli::SSH).to receive(:`).with('ssh ubuntu@1.2.3.4')
      cli.run(`pwd`, args)
    end
  end


  describe "get-uaa-token" do
    let(:args) { %w(get-uaa-token) }
    let(:uaa_token){ rand(9999) }
    let(:opsman_api){ double(get_token: double(info: { 'access_token'=> uaa_token})) }

    before do
      allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
    end

    it "should get-uaa-token to target with the ubuntu user" do
      expect_any_instance_of(OpsManager::Cli::GetUaaToken).to receive('puts').with(uaa_token)
      cli.run(`pwd`, args)
    end
  end

  describe 'get-installation-settings' do
    let(:args) { %w(get-installation-settings /tmp/is.yml) }

    it "should call product.get_installation_settings" do
      expect_any_instance_of(OpsManager::Api::Opsman)
        .to receive(:get_installation_settings).with({write_to: '/tmp/is.yml'})
      cli.run(`pwd`, args)
    end
  end

  describe 'import-stemcell' do
    let(:args) { %w(import-stemcell /tmp/is.yml) }

    it "should call ops_manager.import_stemcell" do
      expect_any_instance_of(OpsManager)
        .to receive(:import_stemcell).with('/tmp/is.yml')
      cli.run(`pwd`, args)
    end
  end

  describe 'delete-unused-products' do
    let(:args) { %w(delete-unused-products) }

    it "should call ops_manager.delete_products" do
      expect_any_instance_of(OpsManager)
        .to receive(:delete_products)
      cli.run(`pwd`, args)
    end
  end

  describe 'get-product-settings' do
    let(:args) { %w(get-product-template example-product) }
    let(:yml){ "---\nproducts: []" }
    let(:product_template_generator){ double(generate: yml).as_null_object }

    before do
      allow(OpsManager::ProductTemplateGenerator)
        .to receive(:new).with('example-product')
        .and_return(product_template_generator)
    end


    it "should return product installation settings" do
      expect_any_instance_of(OpsManager::Cli::GetProductTemplate).to receive(:puts).with( yml )
      cli.run(`pwd`, args)
    end
  end

  describe 'get-installation-logs' do
    let(:args) { ['get-installation-logs', installation_id ] }
    let(:installation_id){ 1 }
    let(:last_installation_id){ 2 }
    let(:installation_logs){ 'logs for installation' }
    let(:last_installation_logs){ 'last installation logs' }
    let!(:installation) do
      object_double(OpsManager::Installation.new(installation_id),
                    logs: installation_logs )
    end
    let!(:last_installation) do
      object_double(OpsManager::Installation.new(installation_id),
                    logs: last_installation_logs)
    end

    describe 'when an installation id is provided' do
      before do
        allow(OpsManager::Installation)
          .to receive(:new).with(installation_id)
          .and_return(installation)
      end

      it "should return installation logs" do
        expect_any_instance_of(OpsManager::Cli::GetInstallationLogs)
          .to receive(:puts).with(installation_logs)
        cli.run(`pwd`, args)
      end
    end

    describe "when provided id is 'last'" do
      let(:args) { ['get-installation-logs', 'last'] }

      before do
        allow(OpsManager::Installation).to receive(:all)
          .and_return([installation, last_installation])
      end

      it 'should returns logs of the last records installation' do
        expect_any_instance_of(OpsManager::Cli::GetInstallationLogs)
          .to receive(:puts).with(last_installation_logs)
        cli.run(`pwd`, args)
      end
    end
  end
end
