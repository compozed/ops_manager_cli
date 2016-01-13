require 'spec_helper'
require 'yaml'

describe OpsManager do
  let(:conf_file){'vsphere.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:opts){ conf.fetch('deployment').fetch('opts') }
  let(:current_vm_name){ "#{conf.fetch('name')}-#{current_version}"}
  let(:current_version){ '1.4.2.0' }
  let(:ops_manager) do
    described_class.new(conf_file).tap do |o|
      o.deployment = deployment
    end
  end
  let(:deployment){ double('deployment',current_version: current_version ).as_null_object }

  it 'has a version number' do
    expect(OpsManager::VERSION).not_to be nil
  end

  describe 'when initializing' do
    it 'initialize with vsphere with provided configurations' do
      opts = conf.fetch('deployment').fetch('opts')
      expect(OpsManager::Vsphere).to receive(:new).with(conf.fetch('name'), conf.fetch('ip'), conf.fetch('username') , conf.fetch('password') , opts)
      ops_manager.deployment
    end
  end

  describe 'run' do
    describe 'when no ops-manager has been deployed' do
      let(:current_version){ nil }

      it 'performs a deployment' do
        expect(ops_manager.deployment).to receive(:deploy)
        expect do
          ops_manager.run
        end.to output(/No OpsManager deployed at #{conf.fetch('ip')}. Deploying .../).to_stdout
      end

      it 'does not performs an upgrade' do
        expect(ops_manager.deployment).to_not receive(:upgrade)
        expect do
          ops_manager.run
        end.to output(/No OpsManager deployed at #{conf.fetch('ip')}. Deploying .../).to_stdout
      end
    end

    describe 'when ops-manager has been deployed and current and desired version match' do
      let(:current_version){ opts.fetch('version') }

      it 'does not performs a deployment' do
        VCR.use_cassette 'deploying same version' do
          expect(ops_manager.deployment).to_not receive(:deploy)
          expect do
            ops_manager.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is already #{ops_manager.new_version}. Skiping .../).to_stdout
        end
      end

      it 'does not performs an upgrade' do
        VCR.use_cassette 'deploying same version' do
          expect(ops_manager.deployment).to_not receive(:upgrade)
          expect do
            ops_manager.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is already #{ops_manager.new_version}. Skiping .../).to_stdout
        end
      end
    end

    describe 'when current version is older than new version' do
      let(:conf_file){'vsphere_newer_version.yml'}

      it 'performs an upgrade' do
        VCR.use_cassette 'deploying newer version' do
          expect(ops_manager.deployment).to receive(:upgrade)
          expect do
            ops_manager.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is #{ops_manager.deployment.current_version}. Upgrading to #{ops_manager.new_version}.../).to_stdout
        end
      end

      it 'does not performs a deployment' do
        VCR.use_cassette 'deploying newer version' do
          expect(ops_manager.deployment).to_not receive(:deploy)
          expect do
            ops_manager.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is #{ops_manager.deployment.current_version}. Upgrading to #{ops_manager.new_version}.../).to_stdout
        end
      end
    end

    describe 'when desired version < existing version' do
    xit 'performs a downgrade'
    end
  end
end
