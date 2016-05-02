require "spec_helper"

describe OpsManager::Cli do
  let(:cli){ described_class }

  describe "target" do
    let(:args) { %w(target 1.2.3.4) }

    it "should call OpsManager.target IP" do
      expect(OpsManager).to receive(:target).with('1.2.3.4')
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
    let(:args) { %w(deploy ops_manager_deployment.yml) }

    it "should call ops_manager.deploy" do
      expect(OpsManager::Deployment).to receive(:new).with('ops_manager_deployment.yml').and_call_original
      expect_any_instance_of(OpsManager::Deployment).to receive(:run)
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
end
