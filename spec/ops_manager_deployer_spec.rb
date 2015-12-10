require 'spec_helper'
require 'yaml'

describe OpsManagerDeployer do
  let(:conf_file){'vsphere.yml'}
  let(:conf){ YAML.load_file(conf_file) }
  let(:ops_manager_deployer){ described_class.new(conf_file) }

  it 'has a version number' do
    expect(OpsManagerDeployer::VERSION).not_to be nil
  end

  describe 'when initializing' do
    it 'should set cloud to OpsManagerDeployer::Vsphere' do
      expect(ops_manager_deployer.cloud).to be_kind_of(OpsManagerDeployer::Vsphere)
    end

    it 'initialize with vsphere with provided configurations' do
      opts = conf.fetch('cloud').fetch('opts')
      expect(OpsManagerDeployer::Vsphere).to receive(:new).with(conf.fetch('ip'), conf.fetch('username') , conf.fetch('password') , opts)
      ops_manager_deployer.cloud
    end
  end

  describe 'run' do
    before { ops_manager_deployer.cloud = double('cloud').as_null_object }

    describe 'when no ops-manager has been deployed' do
      before do
        expect_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ETIMEDOUT)
      end

      it 'current version should be nil' do
        expect(ops_manager_deployer.current_version).to be_nil
      end

      it 'performs a deployment' do
        expect(ops_manager_deployer.cloud).to receive(:deploy)
        expect do
          ops_manager_deployer.run
        end.to output(/No OpsManager deployed at #{conf.fetch('ip')}. Deploying .../).to_stdout
      end

      it 'does not performs an upgrade' do
        expect(ops_manager_deployer.cloud).to_not receive(:upgrade)
        expect do
          ops_manager_deployer.run
        end.to output(/No OpsManager deployed at #{conf.fetch('ip')}. Deploying .../).to_stdout
      end
    end

    describe 'when ops-manager has been deployed and current and desired version match' do
      it 'current version should eq new version' do
        VCR.use_cassette 'deploying same version' do
        expect(ops_manager_deployer.current_version).to eq(ops_manager_deployer.new_version)
        end
      end

      it 'does not performs a deployment' do
        VCR.use_cassette 'deploying same version' do
          expect(ops_manager_deployer.cloud).to_not receive(:deploy)
          expect do
            ops_manager_deployer.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is already #{ops_manager_deployer.new_version}. Skiping .../).to_stdout
        end
      end

      it 'does not performs an upgrade' do
        VCR.use_cassette 'deploying same version' do
          expect(ops_manager_deployer.cloud).to_not receive(:upgrade)
          expect do
            ops_manager_deployer.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is already #{ops_manager_deployer.new_version}. Skiping .../).to_stdout
        end
      end
    end

    describe 'when current version is older than new version' do
      let(:conf_file){'vsphere_newer_version.yml'}

      it 'performs an upgrade' do
        VCR.use_cassette 'deploying newer version' do
          expect(ops_manager_deployer.cloud).to receive(:upgrade)
          expect do
            ops_manager_deployer.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is #{ops_manager_deployer.current_version}. Upgrading to #{ops_manager_deployer.new_version}.../).to_stdout
        end
      end

      it 'does not performs a deployment' do
        VCR.use_cassette 'deploying newer version' do
          expect(ops_manager_deployer.cloud).to_not receive(:deploy)
          expect do
            ops_manager_deployer.run
          end.to output(/OpsManager at #{conf.fetch('ip')} version is #{ops_manager_deployer.current_version}. Upgrading to #{ops_manager_deployer.new_version}.../).to_stdout
        end
      end
    end

    describe 'when desired version < existing version' do
    it 'performs a downgrade'
    end
  end
end
