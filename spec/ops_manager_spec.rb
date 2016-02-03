require 'spec_helper'
require 'yaml'

describe OpsManager do
  let(:ops_manager_deployment_file){'ops_manager_deployment.yml'}
  let(:ops_manager_deployment_conf){ YAML.load_file(ops_manager_deployment_file) }
  let(:product_deployment_file){'product_deployment.yml'}
  let(:opts){ ops_manager_deployment_conf.fetch('opts') }
  let(:current_vm_name){ "#{ops_manager_deployment_conf.fetch('name')}-#{current_version}"}
  let(:target){ '1.2.3.4' }
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:current_version){ '1.4.2.0' }
  let(:ops_manager) do
    described_class.new.tap do |o|
      o.deployment = deployment
    end
  end
  let(:deployment){ double('deployment',current_version: current_version ).as_null_object }

  let(:ops_manager_dir){ "#{ENV['HOME']}/.ops_manager" }
  let(:conf_file_path) { "#{ops_manager_dir}/conf.yml" }

  before{ `rm -rf #{ops_manager_dir}` }

  it 'has a version number' do
    expect(OpsManager::VERSION).not_to be nil
  end

  describe '@set_conf' do
    describe 'when configuration has not been set' do
      before{ `rm -rf #{ops_manager_dir}` }

      it 'should write conf to the yaml' do
        expect do
          OpsManager.set_conf :foo, 'baz'
        end.to change{ OpsManager.get_conf :foo }.from(nil).to('baz')
      end
    end

    describe 'when configuration has been set' do
      before{ OpsManager.set_conf :foo, 'bar' }

      it 'should merge conf to the yaml' do
        expect do
          OpsManager.set_conf :foo, 'baz'
        end.to change{ OpsManager.get_conf :foo }.from('bar').to('baz')
      end

      it 'should warn user that the conf is being changed' do
        expect do
          OpsManager.set_conf :foo, 'baz'
        end.to output(/Changing foo to baz/).to_stdout
      end
    end
  end

  describe '@target' do
    it 'should set conf target' do
      expect do
        OpsManager.target('1.2.3.4')
      end.to change{ OpsManager.get_conf :target }
    end
  end

  describe '@login' do
    it 'should set conf username' do
      expect do
        OpsManager.login('foo', 'bar')
      end.to change{ OpsManager.get_conf :username }
    end

    it 'should set conf password' do
      expect do
        OpsManager.login('foo', 'bar')
      end.to change{ OpsManager.get_conf :password }
    end
  end

  describe 'target_and_login' do
    describe 'when config has credentials' do
      let(:config) do
        {
          'target' => target,
          'username' => username,
          'password' => password
        }
      end

      it 'should target' do
        expect(OpsManager).to receive(:target).with(target)
        ops_manager.target_and_login(config)
      end

      it 'should login' do
        expect(OpsManager).to receive(:login).with(username, password)
        ops_manager.target_and_login(config)
      end
    end
  end

  describe 'when config does not have credentials' do
    let(:config)  {{}}

    it 'should not target' do
      expect(OpsManager).not_to receive(:target).with(target)
      ops_manager.target_and_login(config)
    end

    it 'should not login' do
      expect(OpsManager).not_to receive(:login).with(username, password)
      ops_manager.target_and_login(config)
    end
  end

  describe 'deploy_product' do
    it 'should target_and_login' do
      allow_any_instance_of(OpsManager::Product).to receive(:deploy)
      expect_any_instance_of(OpsManager).to receive(:target_and_login)
      ops_manager.deploy_product(product_deployment_file)
    end

    it 'should execute a product deploy' do
      expect_any_instance_of(OpsManager::Product).to receive(:deploy)
      ops_manager.deploy_product(product_deployment_file)
    end
  end

  describe 'deploy' do
    describe 'when no ops-manager has been deployed' do
      let(:current_version){ nil }

      it 'performs a deployment' do
        expect(ops_manager.deployment).to receive(:deploy)
        expect do
          ops_manager.deploy(ops_manager_deployment_file)
        end.to output(/No OpsManager deployed at #{target}. Deploying .../).to_stdout
      end

      it 'does not performs an upgrade' do
        expect(ops_manager.deployment).to_not receive(:upgrade)
        expect do
          ops_manager.deploy(ops_manager_deployment_file)
        end.to output(/No OpsManager deployed at #{target}. Deploying .../).to_stdout
      end
    end

    describe 'when ops-manager has been deployed and current and desired version match' do
      let(:current_version){ ops_manager_deployment_conf.fetch('version') }

      it 'does not performs a deployment' do
        VCR.use_cassette 'deploying same version' do
          expect(ops_manager.deployment).to_not receive(:deploy)
          expect do
            ops_manager.deploy(ops_manager_deployment_file)
          end.to output(/OpsManager at #{target} version is already #{current_version}. Skiping .../).to_stdout
        end
      end

      it 'does not performs an upgrade' do
        VCR.use_cassette 'deploying same version' do
          expect(ops_manager.deployment).to_not receive(:upgrade)
          expect do
            ops_manager.deploy(ops_manager_deployment_file)
          end.to output(/OpsManager at #{target} version is already #{current_version}. Skiping .../).to_stdout
        end
      end
    end

    describe 'when current version is older than new version' do
      # let(:ops_manager_deployment_file){'vsphere_newer_version.yml'}

      it 'performs an upgrade' do
        allow(ops_manager).to receive(:version).and_return('1.4.3.0')

        VCR.use_cassette 'deploying newer version' do
          expect(ops_manager.deployment).to receive(:upgrade)
          expect do
            ops_manager.deploy(ops_manager_deployment_file)
          end.to output(/OpsManager at #{target} version is #{ops_manager.deployment.current_version}. Upgrading to #{ops_manager_deployment_conf.fetch('version')}.../).to_stdout
        end
      end

      it 'does not performs a deployment' do
        VCR.use_cassette 'deploying newer version' do
          expect(ops_manager.deployment).to_not receive(:deploy)
          expect do
            ops_manager.deploy(ops_manager_deployment_file)
          end.to output(/OpsManager at #{target} version is #{ops_manager.deployment.current_version}. Upgrading to #{ops_manager_deployment_conf.fetch('version')}.../).to_stdout
        end
      end
    end

    describe 'when desired version < existing version' do
      xit 'performs a downgrade'
    end
  end
end
