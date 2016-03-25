require 'spec_helper'
require 'ops_manager/installation_settings'

describe OpsManager::InstallationSettings do
  let(:installation_settings){ described_class.new('../fixtures/installation_settings.json') }

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
