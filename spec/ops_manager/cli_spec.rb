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
      expect_any_instance_of(OpsManager).to receive(:deploy).with('ops_manager_deployment.yml')
      cli.run(`pwd`, args)
    end
  end


  # ./ops_manager deploy-product -c conf.yml
  describe "deploy-product" do
    let(:args) { %w(deploy-product product.yml) }

    it "should call ops_manager.deploy_product" do
      expect_any_instance_of(OpsManager).to receive(:deploy_product).with('product.yml', nil)
      cli.run(`pwd`, args)
    end

    describe "when --force" do
      let(:args) { %w(deploy-product --force product.yml) }

      it "should call ops_manager.deploy_product with force" do
        expect_any_instance_of(OpsManager)
          .to receive(:deploy_product).with('product.yml', true)
        cli.run(`pwd`, args)
      end
    end
  end


  describe 'get-installation-settings' do
    let(:args) { %w(get-installation-settings /tmp/is.yml) }

    it "should call product.get_installation_settings" do
        expect_any_instance_of(OpsManager::Product)
          .to receive(:get_installation_settings).with({write_to: '/tmp/is.yml'})
        cli.run(`pwd`, args)
    end
  end
  #
  # ./ops_manager import-stemcell path/to/stemcell.tgz
  describe 'import-stemcello' do
    let(:args) { %w(import-stemcell /tmp/is.yml) }

    it "should call product.get_installation_settings" do
        expect_any_instance_of(OpsManager)
          .to receive(:import_stemcell).with( '/tmp/is.yml')
        cli.run(`pwd`, args)
    end
  end
end
