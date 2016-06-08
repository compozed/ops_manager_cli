require 'spec_helper'
require 'ops_manager/installation_settings'

describe OpsManager::InstallationSettings do
  let(:parsed_installation_settings){  JSON.parse(File.read(installation_settings_file)) }
  let(:installation_settings_file){ '../fixtures/installation_settings.json' }
  let(:installation_settings){ described_class.new(parsed_installation_settings) }

  describe 'stemcells' do
    it 'should return list of current stemcells' do
      expect(installation_settings.stemcells).to eq(
        [
          {

            version: "3062",
            file: "bosh-stemcell-3062-vsphere-esxi-ubuntu-trusty-go_agent.tgz",
          }
        ]
        )
    end
  end
end
