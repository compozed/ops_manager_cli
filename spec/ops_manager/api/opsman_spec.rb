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
      .with(username, password, 'opsman.admin')
      .and_return(uaa_token)
    allow(CF::UAA::TokenIssuer).to receive(:new)
      .with("https://#{target}/uaa", 'opsman', nil, skip_ssl_validation: true)
      .and_return(token_issuer)

    OpsManager.set_conf( :target, ENV['TARGET'] || target)
    OpsManager.set_conf( :username, ENV['USERNAME'] || username)
    OpsManager.set_conf( :password, ENV['PASSWORD'] || password)

    allow(opsman).to receive(:`) if OpsManager.get_conf(:target) == target
  end

  describe 'upload_installation_assets' do
    before do
      `rm installation_assets.zip`
      `cp ../fixtures/installation_assets.zip .`
    end

    it 'should upload successfully' do
      VCR.use_cassette 'uploading assets' do
        expect do
          opsman.upload_installation_assets
        end.to change{ opsman.get_installation_assets.code.to_i }.from(500).to(200)
      end
    end
  end

  describe 'get_installation_settings' do
    before do
      stub_request(:get, "https://#{target}/api/installation_settings").
        with(:headers => {'Authorization'=>'Basic Zm9vOmJhcg=='}).
        to_return(:status => 200, :body => '{"status":"failed"}')
    end


    it 'should download successfully' do
        opsman.get_installation_settings

      expect(WebMock).to have_requested(:get, "https://#{target}/api/installation_settings")
        .with(:headers => {'Authorization'=>'Basic Zm9vOmJhcg=='})
    end
  end

  describe 'upload_installation_settings' do
    describe 'when success' do
      subject(:response) do
        VCR.use_cassette 'uploading settings' do
          opsman.upload_installation_settings(filepath)
        end
      end

      let(:filepath){ '../fixtures/installation_settings.json' }

      it 'should be successfully' do
        expect(response.code).to eq("200")
      end

      it "should not raise OpsManager::InstallationSettingsError" do
        expect do
          response
        end.not_to raise_exception(OpsManager::InstallationSettingsError)
      end
    end

    describe 'when errors' do
      subject(:response) do
        VCR.use_cassette 'uploading settings errors' do
          opsman.upload_installation_settings(filepath)
        end
      end

      let(:filepath){ '../fixtures/installation_settings.json' }

      it "should not raise OpsManager::InstallationSettingsError" do
        expect do
          response
        end.to raise_exception(OpsManager::InstallationSettingsError)
      end
    end


  end

  describe 'get_installation_assets' do
    before{ `rm -r installation_assets.zip assets` }

    it 'should download successfully' do
      VCR.use_cassette 'installation assets download' do
        opsman.get_installation_assets
        expect(File).to exist("installation_assets.zip" )
        `unzip installation_assets.zip -d assets`
        expect(File).to exist("assets/deployments/bosh-deployments.yml")
        expect(File).to exist("assets/installation.yml")
        expect(File).to exist("assets/metadata/microbosh.yml")
      end
    end
  end

  describe '#create_user' do

    subject(:create_user){ opsman.create_user }
    let(:response){ create_user }

    before do
      stub_request(:post, uri).
        with(:body => body,
             :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})

      opsman.ops_manager_version= ops_manager_version

    end

    describe 'when version 1.5.x' do
      let(:ops_manager_version){ '1.5.5.0' }
      let(:body){ "user[user_name]=foo&user[password]=bar&user[password_confirmantion]=bar"}
      let(:uri){ "#{base_uri}/api/users" }

      it "should successfully create first user" do
          expect(response.code).to eq('200')
      end
    end

    describe 'when version 1.6.x' do
      let(:ops_manager_version){ '1.6.4' }
      let(:uri){ "#{base_uri}/api/setup" }
      let(:body){ "setup[user_name]=foo&setup[password]=bar&setup[password_confirmantion]=bar&setup[eula_accepted]=true" }

      it "should successfully setup first user" do
          expect(response.code).to eq('200')
      end
    end

    describe 'when version 1.7.x' do
      let(:ops_manager_version){ '1.7.5.0' }
      let(:body){ 'setup[decryption_passphrase]=passphrase&setup[decryption_passphrase_confirmation]=passphrase&setup[eula_accepted]=true&setup[identity_provider]=internal&setup[admin_user_name]=foo&setup[admin_password]=bar&setup[admin_password_confirmation]=bar' }
      let(:uri){ "#{base_uri}/api/v0/setup" }

      it "should successfully create first user" do
          expect(response.code).to eq('200')
      end
    end
  end

  describe "#trigger_installation" do
    subject(:response) do
      VCR.use_cassette 'trigger install process' do
        opsman.trigger_installation
      end
    end

    it 'should be successfull' do
      expect(response.code).to eq('200')
    end

    it 'should return installation id' do
      expect(parsed_response.fetch('install').fetch('id')).to be_kind_of(Integer)
    end
  end

  describe "#get_installation" do
    subject(:response) do
      VCR.use_cassette 'getting installation status' do
        opsman.get_installation(10)
      end
    end

    describe 'when installation errors' do
      let(:installation_id){ 1 }

      before do
        stub_request(:get, "https://#{target}/api/installation/#{installation_id}").
          with(:headers => {'Authorization'=>'Basic Zm9vOmJhcg=='}).
          to_return(:status => 200, :body => '{"status":"failed"}')
      end

      subject(:response) do
          opsman.get_installation(installation_id)
      end

      it "should rasie OpsManager::InstallationError" do
        expect do
          response
        end.to raise_exception(OpsManager::InstallationError)
      end
    end

    describe 'when installation running or success' do
      subject(:response) do
        VCR.use_cassette 'getting installation status' do
          opsman.get_installation(10)
        end
      end
      it 'should be successfull' do
        expect(response.code).to eq("200")
      end

      it 'should return installation status' do
        expect(parsed_response.fetch('status')).to be_kind_of(String)
      end
    end

  end

  describe "#delete_products" do
    it "deletes unused products" do
      VCR.use_cassette 'deleting product' do
        opsman.upload_product(filepath)
        expect do
          opsman.delete_products
        end.to change{ opsman.get_products }
      end
    end
  end

  describe "#upgrade_product_installation" do
    let(:guid) { "example-product-31695d885b442a75beee" }
    let(:product_version){ '1.6.2.0' }

    describe "when it applies sucessfully" do
      let(:response) do
        VCR.use_cassette 'upgrade product installation' do
          opsman.upgrade_product_installation(guid, product_version)
        end
      end

      it "should return response" do
        expect(response).to be_kind_of(Net::HTTPOK)
      end

      it 'should return 200' do
        expect(response.code).to eq("200")
      end
    end

    describe "when it applies unsucessfully" do
      let(:response) do
        VCR.use_cassette 'upgrade product installation fails' do
          opsman.upgrade_product_installation(guid, product_version)
        end
      end

      it "should rasie OpsManager::UpgradeError" do
        expect do
          response
        end.to raise_exception(OpsManager::UpgradeError)
      end
    end
  end

  describe "#upload_product" do
    it "deletes unused products" do
      VCR.use_cassette 'deleting product' do
        opsman.delete_products
        expect do
          opsman.upload_product(filepath)
        end.to change{ opsman.get_products }
      end
    end
  end

  describe "#get_products" do

    before do
      stub_request(:get, "https://#{target}/api/products").
        to_return(:status => 200, :body => '[]')
    end

    it 'should perform get to products api endpoint' do
        opsman.get_products

      expect(WebMock).to have_requested(:get, "https://#{target}/api/products")
        .with(:headers => {'Authorization'=>'Basic Zm9vOmJhcg=='})
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
      let(:products) do
        [
          {
            "name" => "p-bosh",
            "product_version" => "1.6.8.0"
          },
          {
            "name" => "p-bosh",
            "product_version" => "1.6.11.0"
          }
        ]
      end

      before do
        products_response = double('fake_products', body: products.to_json)
        allow(opsman).to receive(:get_products).and_return(products_response)
      end

    end
  end


  describe "#import_stemcell" do
    subject(:import_stemcell){ opsman.import_stemcell("../fixtures/stemcell.tgz") }

    let(:response_body){ '{}' }
    let(:response){ import_stemcell }
    let(:status_code){ 200 }
    let(:uri){ "#{base_uri}/api/stemcells" }

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

  describe 'uri_for' do
    before { opsman.ops_manager_version = ops_manager_version }
    let(:endpoint){ '/get_some_resource' }
    subject(:uri){ opsman.uri_for(endpoint) }

    describe 'when ops manager version is 1.5' do
      let(:ops_manager_version){ '1.5' }

      it 'should set the namespace to api/' do
        expect(uri.to_s).to eq("https://#{target}/api#{endpoint}")
      end
    end

    describe 'when ops manager version is 1.6' do
      let(:ops_manager_version){ '1.6' }

      it 'should set the namespace to api/' do
        expect(uri.to_s).to eq("https://#{target}/api#{endpoint}")
      end
    end

    describe 'when ops manager version is 1.7' do
      let(:ops_manager_version){ '1.7' }

      it 'should set the namespace to api/v0' do
        expect(uri.to_s).to eq("https://#{target}/api/v0#{endpoint}")
      end
    end
  end


  %i{ get post put delete }.each do |http_verb|
    describe "#{http_verb}" do
      before do
        stub_request(http_verb, "https://#{target}/api/v0/banana")
      end

      describe 'when ops manager version is 1.7' do
        let(:ops_manager_version){ '1.7' }
        before{ opsman.ops_manager_version = ops_manager_version }

        it 'should include uaa access-token in request' do
            opsman.send(http_verb, '/banana')
            expect(WebMock).to have_requested(http_verb, "https://#{target}/api/v0/banana")
              .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
        end
      end
    end
  end
  describe "#multipart_post" do
    before do
      stub_request(:post, "https://#{target}/api/v0/banana")
    end

    describe 'when ops manager version is 1.7' do
      let(:ops_manager_version){ '1.7' }
      before{ opsman.ops_manager_version = ops_manager_version }

      it 'should include uaa access-token in request' do
          opsman.multipart_post('/banana')
          expect(WebMock).to have_requested(:post, "https://#{target}/api/v0/banana")
            .with(:headers => {'Authorization'=>'Bearer UAA_ACCESS_TOKEN'})
      end
    end
  end
end

