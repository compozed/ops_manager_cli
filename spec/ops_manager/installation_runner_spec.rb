require 'spec_helper'
require 'ops_manager/installation_runner'

describe OpsManager::InstallationRunner do
  let(:installation){ described_class.new }
  let(:installation_id){ rand(9999) }
  let(:installation_response){ double('installation_response', body: "{\"install\":{\"id\":#{installation_id}}}" ) }
  let(:opsman_api){ double.as_null_object }

  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
    allow(opsman_api).to receive(:trigger_installation).and_return(installation_response)
    allow(opsman_api).to receive(:get_current_version).and_return('1.5')
    allow(opsman_api).to receive(:get_staged_products).and_return(double(body: '[]'))
  end

  describe '@initialize' do
    it 'should set installation.id' do
      expect(installation.id).to eq(installation_id)

    end

    it 'should trigger_installation' do
      expect(opsman_api).to receive(:trigger_installation)
      installation
    end

    it 'should default to 1.7' do
    allow(OpsManager::Api::Opsman).to receive(:new).with('1.7')
      .and_return(opsman_api)
      installation
    end

    it 'should send ignore_warnings=true' do
    end

    describe 'when multiple products are staged' do
      let(:get_staged_products_response) do
        double(
          :body =>
            [
              { "guid" => "product1"},
              { "guid" => "product2"}
            ].to_json
        )
      end

      before do
        allow(opsman_api).to receive(:get_staged_products).and_return(get_staged_products_response)
      end

      it 'should set enable_errands with empty hashes' do
        expect(opsman_api).to receive(:trigger_installation)
          .with(body: 'ignore_warnings=true&enabled_errands[product1]{}&enabled_errands[product2]{}')
        installation
      end
    end
  end

  describe '@trigger!' do
    it 'should call new' do
      expect(described_class).to receive(:new)
      described_class.trigger!
    end
  end


  describe "#wait_for_result" do
    let(:success){ double(body: "{\"status\":\"succeded\"}") }
    let(:running){ double(body: "{\"status\":\"running\"}") }

    it 'returns on success' do
      allow(installation).to receive(:sleep)
      expect(opsman_api).to receive(:get_installation)
        .with(installation_id)
        .and_return(running, running, success)
      installation.wait_for_result
    end
  end
end


