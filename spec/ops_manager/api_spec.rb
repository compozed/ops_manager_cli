require 'spec_helper'
require 'ops_manager/api'

describe OpsManager::API do
  class Foo ; include OpsManager::API; end
  let(:api){ Foo.new }
  let(:target){ '1.2.3.4' }
  let(:filepath) { 'example-product-1.6.1.pivotal' }
  let(:parsed_response){ JSON.parse(response.body) }

  before do
    OpsManager.target( ENV['TARGET'] || target)
    OpsManager.login( ENV['USERNAME'] || 'foo', ENV['PASSWORD'] || 'bar')
    allow(api).to receive(:`) if OpsManager.get_conf(:target) == target
  end

  describe 'upload_installation_assets' do
    before do
      `rm installation_assets.zip`
      `cp ../fixtures/installation_assets.zip .`
    end

    it 'should upload successfully' do
      VCR.use_cassette 'uploading assets' do
        expect do
          api.upload_installation_assets
        end.to change{ api.get_installation_assets.code.to_i }.from(500).to(200)
      end
    end
  end

  describe 'get_installation_settings' do
    subject(:response) do
      VCR.use_cassette 'installation settings download' do
        api.get_installation_settings
      end
    end

    it 'should download successfully' do
      expected_json = JSON.parse(File.read('../fixtures/installation_settings.json'))
      expect(JSON.parse(response.body)).to eq(expected_json)
    end
  end

describe 'upload_installation_settings' do
  subject(:response) do
    VCR.use_cassette 'uploading settings' do
      api.upload_installation_settings(filepath)
    end
  end

  let(:filepath){ '../fixtures/installation_settings.json' }

  it 'should be successfully' do
    expect(response.code).to eq("200")
  end
end

describe 'get_installation_assets' do
  before{ `rm -r installation_assets.zip assets` }

  it 'should download successfully' do
    VCR.use_cassette 'installation assets download' do
      api.get_installation_assets
      expect(File).to exist("installation_assets.zip" )
      `unzip installation_assets.zip -d assets`
      expect(File).to exist("assets/deployments/bosh-deployments.yml")
      expect(File).to exist("assets/installation.yml")
      expect(File).to exist("assets/metadata/microbosh.yml")
    end
  end
end

describe '#create_user' do
  let(:base_uri){ 'https://foo:bar@1.2.3.4' }
  before do
    stub_request(:post, uri).
      with(:body => body,
           :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})
  end

  describe 'when version 1.5.x' do
    let(:version){ '1.5.5.0' }
    let(:body){ "user[user_name]=foo&user[password]=bar&user[password_confirmantion]=bar"}
    let(:uri){ "#{base_uri}/api/users" }

    it "should successfully create first user" do
      VCR.turned_off do
        api.create_user(version)
      end
    end
  end

  describe 'when version 1.6.x' do
    let(:version){ '1.6.4' }
    let(:uri){ "#{base_uri}/api/setup" }
    let(:body){ "setup[user_name]=foo&setup[password]=bar&setup[password_confirmantion]=bar&setup[eula_accepted]=true" }

    it "should successfully setup first user" do
      VCR.turned_off do
        api.create_user(version)
      end
    end
  end
end

describe "#trigger_installation" do
  subject(:response) do
    VCR.use_cassette 'trigger install process' do
      api.trigger_installation
    end
  end

  it 'should be successfull' do
    expect(response.code).to eq("200")
  end

  it 'should return installation id' do
    expect(parsed_response.fetch('install').fetch('id')).to be_kind_of(Integer)
  end
end

describe "#get_installation" do
  subject(:response) do
    VCR.use_cassette 'getting installation status' do
      api.get_installation(10)
    end
  end

  it 'should be successfull' do
    expect(response.code).to eq("200")
  end

  it 'should return installation status' do
    expect(parsed_response.fetch('status')).to be_kind_of(String)
  end
end

describe "#delete_products" do
  it "deletes unused products" do
    VCR.use_cassette 'deleting product' do
      api.upload_product(filepath)
      expect do
        api.delete_products
      end.to change{ api.get_products }
    end
  end
end

describe "#upgrade_product_installation" do
  let(:name){ 'example-product' }
  let(:product){ OpsManager::Product.new(name) }
  let(:guid) {product.installation.guid }
  let(:version){ '1.6.2.0' }

  describe "when it applies sucessfully" do
    let(:response) do
      VCR.use_cassette 'upgrade product installation' do
        api.upgrade_product_installation(guid, version)
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
        api.upgrade_product_installation(guid, version)
      end
    end

    it "should return response" do
      expect do
        response
      end.to raise_exception(OpsManager::UpgradeError)
    end
  end
end

describe "#upload_product" do
  it "deletes unused products" do
    VCR.use_cassette 'deleting product' do
      api.delete_products
      expect do
        api.upload_product(filepath)
      end.to change{ api.get_products }
    end
  end
end

describe "#get_products" do
  let(:response) do
    VCR.use_cassette 'listing products' do
      api.get_products
    end
  end

  it "should run successfully" do
    expect(response.code).to eq("200")
  end

  it "should include products in its body" do
    expect(parsed_response).to be_a(Array)
  end
end

describe 'current_version' do
  [ Net::OpenTimeout, Errno::ETIMEDOUT , Net::HTTPFatalError.new( '', '' ) ].each do |error|
    describe "when there is no ops manager and request errors: #{error}" do

      it "should be nil" do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(error)
        expect(api.current_version).to be_nil
      end
    end
  end
end
end

