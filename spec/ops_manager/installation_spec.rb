require 'spec_helper'
require 'ops_manager/installation'

describe OpsManager::Installation do
  let(:installation){ described_class.new }
  let(:installation_id){ rand(9999) }
  let(:installation_response){ double('installation_response', body: "{\"install\":{\"id\":#{installation_id}}}" ) }

  before do
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:trigger_installation)
        .and_return(installation_response)
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_current_version)
        .and_return('1.5')
  end
  describe '@initialize' do
    it 'should set installation.id' do
      expect(installation.id).to eq(installation_id)

    end

    it 'should trigger_installation' do
      expect_any_instance_of(OpsManager::Api::Opsman).to receive(:trigger_installation)
      installation
    end
  end

  describe '@trigger!' do
    it 'should call new' do
      expect(described_class).to receive(:new)
      described_class.trigger!
    end
  end


  describe "#wait_for_result" do
    let(:success){ double(body: "{\"status\":\"succeess\"}") }
    let(:running){ double(body: "{\"status\":\"running\"}") }

    it 'returns on success' do
      allow(installation).to receive(:sleep)
      expect_any_instance_of(OpsManager::Api::Opsman).to receive(:get_installation)
        .with(installation_id)
        .and_return(running, running, success)
      installation.wait_for_result
    end
  end
end


