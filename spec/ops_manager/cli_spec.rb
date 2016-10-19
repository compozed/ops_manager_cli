require "spec_helper"

describe OpsManager::Cli do
  let(:cli){ described_class }
  let!(:opsman_api){ object_double(OpsManager::Api::Opsman.new).as_null_object }


  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
  end

  describe "target" do
    let(:args) { %w(target 1.2.3.4) }

    it "should call OpsManager.set_target IP" do
      expect(OpsManager).to receive(:set_target).with('1.2.3.4')
      cli.run(`pwd`, args)
    end
  end

  describe "status" do
    let(:args) { %w(status) }
    let(:status_response){ 'opsman status' }

    it "should show ops_manager status" do
      allow(OpsManager).to receive(:show_status).and_return(status_response)
      expect_any_instance_of(OpsManager::Cli::Status).to receive(:puts).with(status_response)
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
  describe "deploy-appliance" do
    let(:args) { %w(deploy-appliance ops_manager_deployment.yml) }

    it "should call ops_manager.deploy" do
      expect(OpsManager::ApplianceDeployment).to receive(:new).and_call_original
      expect_any_instance_of(OpsManager::ApplianceDeployment).to receive(:run)
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
    let(:args) { %w(get-installation-settings) }
    let(:installation_settings){ '{"foo": "bar"}' }

    it "should call product.get_installation_settings" do
      allow(opsman_api).to receive(:get_installation_settings).and_return(double(body: installation_settings))
      expect_any_instance_of(OpsManager::Cli::GetInstallationSettings)
        .to receive(:puts).with("---\nfoo: bar\n")
      cli.run(`pwd`, args)
    end
  end

  describe 'import-stemcell' do
    let(:args) { %w(import-stemcell /tmp/is.yml) }

    it "should call ops_manager.import_stemcell" do
      expect(opsman_api).to receive(:import_stemcell).with('/tmp/is.yml')
      cli.run(`pwd`, args)
    end
  end

  describe 'delete-unused-products' do
    let(:args) { %w(delete-unused-products) }

    it "should call ops_manager.delete_products" do
      expect(opsman_api).to receive(:delete_products)
      cli.run(`pwd`, args)
    end
  end

  describe 'get-product-template' do
    let(:args) { %w(get-product-template example-product) }
    let(:product_name){ 'example-product' }
    let(:yml){ "---\nproducts: []" }
    let!(:product_template_generator) do
      object_double(OpsManager::ProductTemplateGenerator.new(product_name), generate_yml: yml).as_null_object
    end

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

  describe 'get-director-template' do
    let(:args) { %w(get-director-template) }
    let(:yml){ "---\nexample: yml" }
    let!(:director_template_generator) do
      object_double(OpsManager::DirectorTemplateGenerator.new, generate_yml: yml).as_null_object
    end

    before do
      allow(OpsManager::DirectorTemplateGenerator).to receive(:new).and_return(director_template_generator)
    end

    it "should return director installation settings" do
      expect_any_instance_of(OpsManager::Cli::GetDirectorTemplate).to receive(:puts).with( yml )
      cli.run(`pwd`, args)
    end
  end

  describe 'get-installation-logs' do
    let(:args) { ['get-installation-logs', installation_id.to_s ] }
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

  describe 'curl' do
    let(:endpoint){ '/custom/endpoint' }
    let(:body){ 'result' }


    describe 'when no method is provided' do
      let(:method){ :get }
      let(:args) { ['curl', endpoint] }

      before do
        allow(opsman_api).to receive(:authenticated_get)
          .with(endpoint).and_return(double(body: body))
      end

      it 'should perform get with provided endpoint' do
        expect_any_instance_of(OpsManager::Cli::Curl)
          .to receive(:puts).with(body)
        cli.run(`pwd`, args)
      end
    end

    describe 'when post' do
      let(:args) { ['curl', '-X POST', endpoint] }

      before do
        allow(opsman_api).to receive(:authenticated_post)
          .with(endpoint).and_return(double(body: body))
      end

      it 'should perform post with provided endpoint' do
        expect_any_instance_of(OpsManager::Cli::Curl)
          .to receive(:puts).with(body)
        cli.run(`pwd`, args)
      end
    end

    describe 'when method not supported' do
      let(:args) { ['curl', '-X UNSUPPORTED_METHOD', endpoint] }

      before do
        allow(opsman_api).to receive(:authenticated_post)
          .with(endpoint).and_return(double(body: body))
      end

      it 'should perform post with provided endpoint' do
        expect_any_instance_of(OpsManager::Cli::Curl)
          .to receive(:puts).with('Unsupported method: UNSUPPORTED_METHOD')
        cli.run(`pwd`, args)
      end
    end
  end
end
