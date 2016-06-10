require 'spec_helper'
require 'ops_manager/installation'

describe OpsManager::Installation do
  let!(:opsman_api){ object_double(OpsManager::Api::Opsman.new) }
  let(:first_installation){ described_class.new(1) }
  let(:last_installation){ described_class.new(2) }
  let(:installations) do
    { "installations" => [
      { "id" => last_installation.id },
      { "id" => first_installation.id }
    ]
    }
  end
  let(:installations_response) do
    double(body: installations.to_json)
  end
  before do
    allow(opsman_api).to receive(:get_installations)
      .and_return(installations_response)
    allow(OpsManager::Api::Opsman)
      .to receive(:new).and_return(opsman_api)
  end

  describe '#logs' do
    let(:installation_logs_response) do
      double(body: '{"logs": "some logs"}')
    end
    before do
      allow(opsman_api).to receive(:get_installation_logs)
        .with(first_installation.id)
        .and_return(installation_logs_response)
    end

    it 'should return the installation logs' do
      expect(first_installation.logs).to eq('some logs')
    end
  end

  describe '@all' do
    subject(:all){ described_class.all }

    it 'should return an array' do
      expect(all).to be_kind_of(Array)
    end

    it 'should return multiple installations' do
      expect(all.count).to eq(2)
    end

    it 'should returns installations in the correct order' do
      expect(all.last.id).to eq(last_installation.id)
    end
  end

  describe '@new' do
    it 'should set id' do
      expect(first_installation.id).to be_kind_of(Fixnum)
    end
  end
end
