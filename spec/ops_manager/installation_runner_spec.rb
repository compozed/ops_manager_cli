require 'spec_helper'
require 'ops_manager/installation_runner'

describe OpsManager::InstallationRunner do
  let(:installation_runner){ described_class.new }
  let(:installation_id){ rand(9999) }
  let(:installation_response){ double('installation_response', body: "{\"install\":{\"id\":#{installation_id}}}" ) }
  let(:product_guid){ "product1" }
  let(:opsman_api){ double.as_null_object }
  let(:get_staged_products_response){ double(body: '[]') }
  let(:get_staged_products_errands_response){ double(body: '{ "errands": []}') }

  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
    allow(opsman_api).to receive(:trigger_installation).and_return(installation_response)
    allow(opsman_api).to receive(:get_staged_products).and_return(get_staged_products_response)
    allow(opsman_api).to receive(:get_staged_products_errands).with(product_guid).and_return(get_staged_products_errands_response)
  end

  describe '#trigger' do
    subject(:trigger){ installation_runner.trigger! }
    let(:get_staged_products_response){ double( body: [ { "guid" =>  product_guid }].to_json, code: 200) }
    let(:get_staged_products_errands_response) do
      double(
        code: 200,
        body:
        { "errands" => [
          { "name" => "errand1",
            "post_deploy" => true,
            "pre_delete" => false
          },
          { "name" => "errand2",
            "post_deploy" => false,
            "pre_delete" => true
          }]}.to_json )
    end

    it 'should trigger_installation' do
      expect(opsman_api).to receive(:trigger_installation)
      installation_runner.trigger!
    end

    it 'should set installation.id' do
      expect do
        installation_runner.trigger!
      end.to change{installation_runner.id }.from(nil).to(installation_id)
    end

    it 'should set enable_errands for all products' do
      expect(opsman_api).to receive(:trigger_installation)
        .with(body: 'ignore_warnings=true&enabled_errands[product1][post_deploy_errands][]=errand1')
      trigger
    end

    describe 'when product errands endpoint does not exists' do
      let(:get_staged_products_errands_response){ double(body: '', code: 404) }

      it 'should set enable_errands for all products' do
        expect(opsman_api).to receive(:trigger_installation)
          .with(body: 'ignore_warnings=true&enabled_errands[product1]{}')
        trigger
      end

    end
  end

  describe '@trigger!' do
    subject(:trigger){ described_class.trigger! }

    it 'should defer call to #trigger' do
      expect_any_instance_of(OpsManager::InstallationRunner).to receive(:trigger!)
      trigger
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


