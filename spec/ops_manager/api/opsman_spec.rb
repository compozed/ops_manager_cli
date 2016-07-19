require 'spec_helper'
require 'ops_manager/api/opsman'

describe OpsManager::Api::Opsman do
  let(:opsman){ OpsManager::Api::Opsman.new }
  let(:target){ '1.2.3.4' }
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:base_uri){ 'https://1.2.3.4' }
  let(:filepath) { 'example-product-1.6.1.pivotal' }
  let(:parsed_response){ JSON.parse(response.body) }
  let(:token_issuer){ double }
  let(:uaa_token){ double(info: {'access_token' => "UAA_ACCESS_TOKEN" }) }

  before do
    allow(token_issuer).to receive(:owner_password_grant)
      .with('admin', password, 'opsman.admin')
      .and_return(uaa_token)
    allow(CF::UAA::TokenIssuer).to receive(:new)
      .with("https://#{target}/uaa", 'opsman', nil, skip_ssl_validation: true)
      .and_return(token_issuer)

    OpsManager.set_conf(:target, ENV['TARGET'] || target)
    OpsManager.set_conf(:username, ENV['USERNAME'] || username)
    OpsManager.set_conf(:password, ENV['PASSWORD'] || password)

    allow(opsman).to receive(:`) if OpsManager.get_conf(:target) == target
  end

  describe '#upload_product' do
    subject(:upload_product){ opsman.upload_product(product_filepath) }
    let(:product_filepath){ 'example-product.pivotal' }

    it 'performs the correct curl' do
      expect(opsman).to receive(:`).with("curl -k \"https://#{target}/api/v0/available_products\" -F 'product[file]=@#{product_filepath}' -X POST -H 'Authorization: Bearer UAA_ACCESS_TOKEN'").and_return('{}')
      upload_product
    end

    describe 'when upload product errors' do
      let(:body){ '{"error":"something went wrong"}' }

      before { allow(opsman).to receive(:`).and_return(body) }

      it 'should raise an exception' do
        expect{ upload_product }.to raise_error{ OpsManager::ProductUploadError }
      end
    end
  end

  describe '#upload_installation_assets' do
    before do
      allow(UploadIO).to receive(:new).with("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
      stub_request(:post, "https://#{target}/api/v0/installation_asset_collection").
        to_return(:status => 200, :body => '{}')
    end

    it 'should upload successfully' do
      opsman.upload_installation_assets
      expect(WebMock).to have_requested(:post, "https://#{target}/api/v0/installation_asset_collection")
    end

    it 'should not send uaa token' do
      opsman.upload_installation_assets
      expect(WebMock).not_to have_requested(:post, "https://#{target}/api/v0/installation_asset_collection").
        with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe "#get_staged_products" do
    let(:uri){ "https://#{target}/api/v0/staged/products" }
    before do
      stub_request(:get, uri).
        to_return(:status => 200, :body => "[]")
    end

    it 'should get successfully' do
      opsman.get_staged_products
      expect(WebMock).to have_requested(:get, uri).
        with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe '#get_installation_assets' do
    let(:uri){ "https://#{target}/api/v0/installation_asset_collection" }

    before do
      stub_request(:get, uri).
        to_return(:status => 200, :body => '{}')
    end

    it 'should download successfully' do
      opsman.get_installation_assets
      expect(WebMock).to have_requested(:get, uri)
        .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end


  describe 'get_installation_settings' do
    let(:uri){ "https://#{target}/api/installation_settings" }

    before do
      stub_request(:get, uri).
        to_return(:status => 200, :body => '{"status":"failed"}')
    end


    it 'should download successfully' do
      opsman.get_installation_settings
      expect(WebMock).to have_requested(:get, "https://#{target}/api/installation_settings")
        .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe 'upload_installation_settings' do
    let(:filepath){ '../fixtures/installation_settings.json' }
    let(:uri){ "https://#{target}/api/installation_settings" }
    before do
      stub_request(:post, uri).
        to_return(status: http_code, body: '{"errors":["error 1", "error 2"]}')
    end

    describe 'when success' do
      let(:body){ '{}' }
      let(:http_code){ 200}

      it 'performs the correct request' do
        opsman.upload_installation_settings(filepath)
        expect(WebMock).to have_requested(:post, uri).
          with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
      end
    end

    describe 'when errors' do
      let(:http_code){ 500 }
      let(:body){ '{"errors":["error 1", "error 2"]}' }


      it "should not raise OpsManager::InstallationSettingsError" do
        expect do
          opsman.upload_installation_settings(filepath)
        end.to raise_exception(OpsManager::InstallationSettingsError)
      end
    end
  end

  describe '#create_user' do
    subject(:create_user){ opsman.create_user }
    let(:response){ create_user }

    before do
      stub_request(:post, uri).
        with(:body => body).
        to_return(:status => 200, :body => "", :headers => {})

    end

    describe 'when version 1.7.x' do
      let(:body){ 'setup[decryption_passphrase]=passphrase&setup[decryption_passphrase_confirmation]=passphrase&setup[eula_accepted]=true&setup[identity_provider]=internal&setup[admin_user_name]=foo&setup[admin_password]=bar&setup[admin_password_confirmation]=bar' }
      let(:uri){ "#{base_uri}/api/v0/setup" }

      it "should successfully create first user" do
        expect(response.code).to eq('200')
      end

      it 'should not send any authentication on post request' do
        create_user
        expect(WebMock).not_to have_requested(:post, uri)
          .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
      end
    end
  end

  describe "#trigger_installation" do
    let(:body){ '{"install":{"id":10}}' }
    let(:uri){ "https://#{target}/api/v0/installations" }

    before do
      stub_request(:post, uri).
        with(:body => body).
        to_return(:status => 200, :body => "", :headers => {})
    end

  end

  describe "#get_installation" do
    let(:installation_id){ 1 }
    let(:uri){ "https://#{target}/api/v0/installations/#{installation_id}" }

    before do
      stub_request(:get, uri).
        to_return(status: 200, body: body)
    end

    describe 'when success' do
      let(:body){ '{"status":"succeded"}' }

      it 'performs the correct request' do
        opsman.get_installation(installation_id)

        expect(WebMock).to have_requested(:get, uri)
          .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
      end
    end

    describe 'when errors' do
      let(:body){'{"status":"failed"}'}

      it "should rasie OpsManager::InstallationError" do
        expect do
          opsman.get_installation(installation_id)
        end.to raise_exception(OpsManager::InstallationError)
      end
    end
  end

  describe "#delete_products" do
    let(:uri){ "https://#{target}/api/v0/products" }

    before do
      stub_request(:delete, uri).
        to_return(status: 200, body: '{}')
    end

    it 'performs the correct request' do
      opsman.delete_products
      expect(WebMock).to have_requested(:delete, uri)
        .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe "#upgrade_product_installation" do
    let(:uri){ "https://#{target}/api/v0/staged/products/#{guid}" }
    let(:guid) { 'example-product-31695d885b442a75beee' }
    let(:product_version){ '1.7.2.0' }

    before do
      stub_request(:put, uri).
        to_return(status: http_code , body: '{}')
    end

    describe "when success" do
      let(:http_code){ 200 }

      it 'performs the correct request' do
        opsman.upgrade_product_installation(guid, product_version)
        expect(WebMock).to have_requested(:put, uri).
          with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
      end
    end

    describe "when failure" do
      let(:http_code){ 422 }
      let(:body){ '{{"errors":["Version 123 of product Pivotal Elastic Runtime is already in use."]}" }' }

      it "should raise OpsManager::UpgradeError" do
        expect do
          opsman.upgrade_product_installation(guid, product_version)
        end.to raise_exception(OpsManager::UpgradeError)
      end
    end
  end

  describe "#get_available_products" do
    let(:uri){"https://#{target}/api/v0/available_products"}
    before do
      stub_request(:get, uri).
        to_return(:status => 200, :body => '[]')
    end

    it 'should perform get to products api endpoint' do
      opsman.get_available_products

      expect(WebMock).to have_requested(:get, uri).
        with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe 'get_current_version' do
    [ Net::OpenTimeout, Errno::ETIMEDOUT ,
      Net::HTTPFatalError.new( '', '' ), Errno::EHOSTUNREACH ].each do |error|
      describe "when there is no ops manager and request errors: #{error}" do

        it "should be nil" do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(error)
          expect(opsman.get_current_version).to be_nil
        end
      end
    end

    describe 'when there are multiple director product tiles uploaded' do
      let(:latest_version){ "1.6.11.0" }
      let(:products) do
        [
          {
            "name" => "p-bosh",
            "product_version" => "1.6.8.0"
          },
          {
            "name" => "p-bosh",
            "product_version" => "1.6.11.1"
          }
        ]
      end

      before do
        products_response = double('fake_products', body: products.to_json)
        allow(opsman).to receive(:get_available_products).and_return(products_response)
      end

      it 'should return the latest one' do
        expect(opsman.get_current_version).to eq("1.6.11.1")
      end

      describe 'when version ends in .0' do
       let(:products){ [ { "name" => "p-bosh", "product_version" => "1.6.11.0" } ] }

        it 'should remove .0' do
          expect(opsman.get_current_version).to eq("1.6.11")
        end
      end
    end
  end


  describe "#import_stemcell" do
    subject(:import_stemcell){ opsman.import_stemcell("stemcell.tgz") }

    let(:response_body){ '{}' }
    let(:response){ import_stemcell }
    let(:status_code){ 200 }
    let(:uri){ "#{base_uri}/api/v0/stemcells" }

    before do
      stub_request(:post, uri).to_return(status: status_code, body: response_body)
    end

    it "should run successfully" do
      expect(response.code).to eq("200")
    end

    it "should include products in its body" do
      expect(parsed_response).to eq({})
    end

    describe  "when stemcell is nil" do
      it "should skip" do
        expect(opsman).not_to receive(:puts).with(/====> Uploading stemcell.../)
        opsman.import_stemcell(nil)
      end
    end

    describe "when fails to upload stemcell" do
      let(:status_code){ 400 }
      let(:response_body){ '{"error": "someting failed" }' }

      it "should raise StemcellUploadError" do
        expect{ import_stemcell }.to raise_error{ OpsManager::StemcellUploadError }
      end
    end
  end

  describe "#get_installations" do
    subject(:get_installations){ opsman.get_installations }

    let(:response_body){ '{ "installations": []}' }
    let(:response){ get_installations }
    let(:status_code){ 200 }
    let(:uri){ "#{base_uri}/api/v0/installations" }

    before do
      stub_request(:get, uri).to_return(status: status_code, body: response_body)
    end

    it "should run successfully" do
      expect(response.code).to eq("200")
    end

    it "should include products in its body" do
      expect(parsed_response).to eq({ 'installations' => []})
    end

    it 'should not send authentication on get request' do
      get_installations
      expect(WebMock).to have_requested(:get, uri)
        .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe "#get_installation_logs" do
    let(:installation_id){ 1 }
    let(:uri){ "https://#{target}/api/v0/installations/#{installation_id}/logs" }
    let(:body){ '{"logs":"some-text"}' }
    let(:status_code){ 200 }

    before do
      stub_request(:get, uri).
        to_return(status: status_code, body: body)
    end

    it 'performs the correct request' do
      opsman.get_installation_logs(installation_id)

      expect(WebMock).to have_requested(:get, uri)
        .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
    end
  end

  describe 'get_token' do
    describe 'when credentials are incorrect' do
      before do
        allow(token_issuer).to receive(:owner_password_grant)
          .and_raise(CF::UAA::TargetError.new)
      end

      it 'it should be nil' do
        expect(opsman.get_token).to be_nil
      end
    end
  end
end
