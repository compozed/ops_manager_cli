require "spec_helper"

describe OpsManager::Cli do
  let(:cli){ described_class }

  describe "deploy" do
    let(:args) { %w(deploy --config vsphere.yml) }

    it "should call OpsManager.deploy" do
      expect_any_instance_of(OpsManager).to receive(:deploy)
      cli.run(`pwd`, args)
    end
  end
end
