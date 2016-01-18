require 'spec_helper'
require 'ops_manager/product'

describe OpsManager::Product do
  let(:conf_file){ 'product_deployment.yml' }
  let(:product){ described_class.new(name, filepath) }
  let(:conf){ YAML.load_file(conf_file) }
  let(:ip){ OpsManager.get_conf :target }
  let(:username){ OpsManager.get_conf :username }
  let(:password){ OpsManager.get_conf :password }
  let(:name){ conf.fetch('name') }
  let(:filepath){ conf.fetch('filepath') }


  describe "#initialize" do
    %w(name filepath).each do |attr|
      it "sets the #{attr}" do
        expect(product.send(attr)).to eq(send(attr))
      end
    end
  end

  describe "#upload" do
    before do
      `rm product.pivotal`
      `cp ../fixtures/product.pivotal .`
    end

    it "uploads product tile" do

      VCR.use_cassette 'uploading product' do
        expect do
          product.upload
        end
      end.to change{ OpsManager::Product.list.body.include?('cf') }
    end
  end

  describe "#products" do
    it "should return products" do
      VCR.use_cassette 'list products' do
        expect(product.list.code).to eq(200)
        expect(product.list.body).to include('elastic-runtime')
      end
    end
  end

  describe "deploy" do
    describe "when is the first time that it gets deployed" do
      it "upload new product"
      it "should add new product" #check on this
      it "upload updated installation settings"
      it "perform deployment"
    end

    describe "when desired version is newer than actual version"
    describe "when desired version equals actual version"
  end
end
