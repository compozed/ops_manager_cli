require 'spec_helper'
require 'ops_manager/installation_runner'

describe OpsManager::InstallationRunner do
  let(:installation_runner){ described_class.new }
  let(:installation_id){ rand(9999) }
  let(:errand_name){ "errand#{rand(9999)}" }
  let(:installation_response){ double('installation_response', body: "{\"install\":{\"id\":#{installation_id}}}" ) }
  let(:product_guid){ "product_1_guid" }
  let(:opsman_api){ double.as_null_object }
  let(:get_staged_products_response){ double(body: '[]') }
  let(:staged_products_errands_response){ double(body: '{ "errands": []}') }

  before do
    allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
    allow(opsman_api).to receive(:trigger_installation).and_return(installation_response)
    allow(opsman_api).to receive(:get_staged_products).and_return(get_staged_products_response)
    allow(opsman_api).to receive(:get_staged_products_errands).with(product_guid).and_return(staged_products_errands_response)
  end

  describe '#trigger' do
    subject(:trigger){ installation_runner.trigger! }
    let(:get_staged_products_response){ double( body: [ { "guid" =>  product_guid }].to_json, code: 200) }
    let(:staged_products_errands_response) do
      double(
        code: '200',
        body:
        { "errands" => [
          { "name" => errand_name,
            "post_deploy" => true,
            "pre_delete" => false
          },
          { "name" => "pre_deploy_errand",
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
        .with(
          headers: {"Content-Type" => "application/json"},
          body: {
            "errands"=> {
              "product_1_guid"=> {
                "run_post_deploy"=> {
                errand_name => true
                }
              }
          },
        "ignore_warnings"=> true
        }.to_json )
      trigger
    end

    describe 'when product errands do not exist' do
      let(:staged_products_errands_response){ double(body: '', code: 404) }

      it 'should not return any errands' do
        expect(opsman_api).to receive(:trigger_installation)
          .with(
            headers: {"Content-Type" => "application/json"},
          body: {
            "errands"=> {},
            "ignore_warnings"=> true
        }.to_json )
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


