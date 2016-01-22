require 'spec_helper'
require 'ops_manager/api'

describe OpsManager::API do
  class Foo ; include OpsManager::API; end
  let(:api){ Foo.new }
  let(:filepath) { 'example-product-1.6.1.pivotal' }
  let(:parsed_response){ JSON.parse(response.body) }

  before do
    `rm #{filepath} ; cp ../fixtures/#{filepath} .`
    allow(api).to receive(:`) if OpsManager.get_conf(:target) == '1.2.3.4'
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
      res = nil
      VCR.use_cassette 'trigger install process' do
        res = api.trigger_installation
      end
      res
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
      res = nil
        VCR.use_cassette 'getting installation status' do
        res = api.get_installation(10)
      end
      res
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

    it 'Should change version of installation' do
      VCR.use_cassette 'upgrade product installation' do
        expect do
          api.upgrade_product_installation(guid, version)
        end.to change{ product.installation.version }.from('1.6.1.0').to('1.6.2.0')
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
    it "list available products" do
      VCR.use_cassette 'listing products' do
        expect(api).to receive(:get).and_call_original
        products = api.get_products
        expect(products).to be_a(Array)
        expect(products).not_to be_empty
      end
    end
  end
end

