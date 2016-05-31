require 'spec_helper'

describe OpsManager::ProductInstallation do
  let(:name){ 'microbosh' }
  let(:opsman_api) do
    res = double( body: File.read('../fixtures/installation_settings.json'))
    double(get_installation_settings: res)
  end

  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
  end

  describe '@find' do
    subject(:installation){ described_class.find(name) }

    it "should return guid" do
      expect(installation.guid).to eq('microbosh-9b6fc5940334026515a3')
    end

    it "should return version" do
      expect(installation.version).to eq('1.5.5.0')
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
