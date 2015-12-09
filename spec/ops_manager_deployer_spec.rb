require 'spec_helper'
require 'yaml'

describe OpsManagerDeployer do
  let(:conf_file){'conf.yml'}
  let(:ops_manager_deployer){ described_class.new(conf_file) }

  it 'has a version number' do
    expect(OpsManagerDeployer::VERSION).not_to be nil
  end

  describe 'new' do
    describe 'when vsphere' do
      let(:conf_file){'vsphere.yml'}

      it 'should set @cloud to OpsManagerDeployer::Vsphere' do
        expect(ops_manager_deployer.cloud).to be_kind_of(OpsManagerDeployer::Vsphere)
      end

      it 'initialize with vsphere conf' do
        opts = YAML.load_file(conf_file).fetch('cloud').fetch('opts')
        expect(OpsManagerDeployer::Vsphere).to receive(:new).with(opts)
        ops_manager_deployer.cloud
      end
    end
  end

  describe 'run' do
    describe 'when no ops-manager has been deployed' do
      it 'performs @cloud.deploy'
    end

    describe 'when ops-manager has been deployed' do
      describe 'when desired version == existing version' do
      it 'performs @cloud.ommit'
      end

      describe 'when desired version > existing version' do
      it 'performs @cloud.upgrade'
      end

      describe 'when desired version < existing version' do
      it 'performs @cloud.ommit'
      end
    end
  end
end
