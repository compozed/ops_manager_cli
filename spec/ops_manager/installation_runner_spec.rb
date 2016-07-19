require 'spec_helper'
require 'ops_manager/installation_runner'

describe OpsManager::InstallationRunner do
  let(:installation_runner){ described_class.new }
  let(:installation_id){ rand(9999) }
  let(:installation_response){ double('installation_response', body: "{\"install\":{\"id\":#{installation_id}}}" ) }
  let(:opsman_api){ double.as_null_object }

  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
    allow(opsman_api).to receive(:trigger_installation).and_return(installation_response)
    allow(opsman_api).to receive(:get_current_version).and_return('1.5')
    allow(opsman_api).to receive(:get_staged_products).and_return(double(body: '[]'))
  end

  describe '#trigger' do
    it 'should trigger_installation' do
      expect(opsman_api).to receive(:trigger_installation)
      installation_runner.trigger!
    end

    it 'should set installation.id' do
      expect do
        installation_runner.trigger!
      end.to change{installation_runner.id }.from(nil).to(installation_id)
    end
  end

  describe '@initialize' do

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

      it 'should set enable_errands for all products' do
        expect(opsman_api).to receive(:trigger_installation)
          .with(body: 'ignore_warnings=true&enabled_errands[product1]{}&enabled_errands[product2]{}')
        installation_runner
      end
    end
  end

  describe '@trigger!' do
    it 'should defer call to #trigger' do
      expect_any_instance_of(OpsManager::InstallationRunner).to receive(:trigger!)
      described_class.trigger!
    end
  end


  describe "#wait_for_result" do
    let(:success){ double(body: "{\"status\":\"succeded\"}") }
    let(:running){ double(body: "{\"status\":\"running\"}") }

    it 'returns on success' do
      allow_any_instance_of(OpsManager::InstallationRunner).to receive(:sleep)
      expect(opsman_api).to receive(:get_installation)
        .with(installation_id)
        .and_return(running, running, success)

      described_class.trigger!.wait_for_result
    end
  end
end


