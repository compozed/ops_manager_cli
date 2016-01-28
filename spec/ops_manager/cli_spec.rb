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
      expect_any_instance_of(OpsManager).to receive(:deploy_product).with('product.yml')
      cli.run(`pwd`, args)
    end
  end

  #
  # ./ops_manager provision stemcell -p path/to/stemcell.tgz -t IP -u USER -p PASSWORD
end
