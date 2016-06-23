require 'spec_helper'

describe OpsManager::ProductInstallation do

  let(:guid){ 'abc123' }
  let(:current_version){ '1.6.2.0' }
  let(:prepared){ true }
  let(:product_installation){ described_class.new(guid, current_version, prepared) }
  let(:name){ 'microbosh' }
  let!(:opsman_api) do
    res = double( body: File.read('../fixtures/installation_settings.json'))
    object_double(OpsManager::Api::Opsman.new, get_installation_settings: res)
  end

  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
  end

  describe '#current_version' do
    it 'should ve a semver' do
      expect(product_installation.current_version).to be_kind_of(OpsManager::Semver)

  end

  end

  describe '@find' do
    subject(:installation){ described_class.find(name) }

    it "should return guid" do
      expect(installation.guid).to eq('microbosh-9b6fc5940334026515a3')
    end

    it "should return version" do
      expect(installation.current_version.to_s).to eq('1.5.5.0')
    end

    it "should fetch installation_settings#prepared entry" do
      expect(installation).to be_prepared
    end

    describe "when the product installation does not exists" do
      let(:name){ 'imaginary-product' }

      it "should be nil" do
        expect(installation).to be_nil
      end
    end
  end
end
