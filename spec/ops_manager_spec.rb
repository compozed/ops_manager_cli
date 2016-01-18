require 'spec_helper'
require 'yaml'

describe OpsManager do
  let(:ops_manager_deployment_file){'ops_manager_deployment.yml'}
  let(:ops_manager_deployment_conf){ YAML.load_file(ops_manager_deployment_file) }
  let(:product_deployment_file){'product_deployment.yml'}
  let(:opts){ ops_manager_deployment_conf.fetch('opts') }
  let(:current_vm_name){ "#{ops_manager_deployment_conf.fetch('name')}-#{current_version}"}
  let(:target){ OpsManager.get_conf :target }
  let(:username){ OpsManager.get_conf :username }
  let(:password){ OpsManager.get_conf :password }

  let(:current_version){ '1.4.2.0' }
  let(:ops_manager) do
    described_class.new.tap do |o|
      o.deployment = deployment
    end
  end
  let(:deployment){ double('deployment',current_version: current_version ).as_null_object }

  let(:ops_manager_dir){ "#{ENV['HOME']}/.ops_manager" }
  let(:conf_file_path) { "#{ops_manager_dir}/conf.yml" }
  let(:ops_manager_conf){ { target: 'IP', username: 'foo', password: 'bar' } }

  before do
    ENV['HOME'] = ENV['PWD']
    OpsManager.target('1.2.3.4')
    OpsManager.login('foo', 'bar')
  end


  it 'has a version number' do
    expect(OpsManager::VERSION).not_to be nil
  end

  describe '@target' do
    describe 'when ~/.ops_manager/conf.yml exists' do
      before do
        Dir.mkdir(ops_manager_dir) unless Dir.exists?(ops_manager_dir)
        File.open(conf_file_path, 'w'){|f| f.write(ops_manager_conf.to_yaml) }
      end

      it 'should override target' do
        expect do
          OpsManager.target('1.2.3.4')
        end.to change{
          YAML.load_file(conf_file_path).fetch(:target )
        }.from("IP").to('1.2.3.4')
      end

      it 'should keep other configurations' do
        expect do
          OpsManager.target('1.2.3.4')
        end.not_to change{ YAML.load_file(conf_file_path).keys }
      end
    end

    describe 'when ~/.ops_manager/conf.yml does not exists' do
      before{ `rm -rf #{ops_manager_dir}` }

      it 'should store ip in $HOME/.ops_manager/conf.yml' do
        expect do
          OpsManager.target('1.2.3.4')
        end.to change{ File.exists?(conf_file_path) }.to(true)
        expect(YAML.load_file(conf_file_path).fetch(:target)).to eq('1.2.3.4')
      end
    end
  end

  describe '@login' do
    describe 'when ~/.ops_manager/conf.yml exists' do
      before do
        Dir.mkdir(ops_manager_dir) unless Dir.exists?(ops_manager_dir)
        File.open(conf_file_path, 'w'){|f| f.write(ops_manager_conf.to_yaml) }
      end

      it 'should override username' do
        expect do
          OpsManager.login( 'luke', 'daveisawesome')
        end.to change{
          YAML.load_file(conf_file_path).fetch(:username)
        }.from('foo').to('luke')
      end

      it 'should override password' do
        expect do
          OpsManager.login( 'luke', 'daveisawesome')
        end.to change{
          YAML.load_file(conf_file_path).fetch(:password)
        }.from('bar').to('daveisawesome')
      end


      it 'should keep other configurations' do
        expect do
          OpsManager.login( 'luke', 'daveisawesome')
        end.not_to change{ YAML.load_file(conf_file_path).keys }
      end
    end

    describe 'when ~/.ops_manager/conf.yml does not exists' do
      before{ `rm -rf #{ops_manager_dir}` }

      it 'should store ip in $HOME/.ops_manager/conf.yml' do
        expect do
          OpsManager.login( 'luke', 'daveisawesome')
        end.to change{ File.exists?(conf_file_path) }.to(true)
        expect(YAML.load_file(conf_file_path).fetch(:username)).to eq('luke')
        expect(YAML.load_file(conf_file_path).fetch(:password)).to eq('daveisawesome')
      end
    end
  end

  describe 'deploy_product' do
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
          end.to output(/OpsManager at #{target} version is already #{current_version} Skiping .../).to_stdout
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
