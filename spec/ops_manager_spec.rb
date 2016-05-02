require 'spec_helper'
require 'yaml'

describe OpsManager do
  let(:product_deployment_file){'product_deployment.yml'}
  let(:current_vm_name){ "ops-manager-#{current_version}"}
  let(:target){ '1.2.3.4' }
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:ops_manager) { described_class.new }

  before{ `rm -rf #{OpsManager.session_config_dir}` }

  it 'has a version number' do
    expect(OpsManager::VERSION).not_to be nil
  end

  describe '@target' do
    let(:net_ping){ double(ping?: pingable?) }
    before do
      OpsManager.set_conf(:target, nil)
      allow(Net::Ping::HTTP).to receive(:new).with("https://#{target}").and_return(net_ping)
    end

    describe 'when target is pingable' do
      let(:pingable?){ true }

      it 'should set conf target' do
        expect do
          OpsManager.target(target)
        end.to change{ OpsManager.get_conf :target }.from(nil).to(target)
      end
    end

    describe 'when target is not pingable' do
      let(:pingable?){ false }

      it 'should set conf target' do
        expect do
          OpsManager.target(target)
        end.not_to change{ OpsManager.get_conf :target }
      end
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

  describe '@target_and_login' do
    before do
      allow(OpsManager).to receive(:target)
      allow(OpsManager).to receive(:login)
    end

    describe 'when config has credentials' do
      subject(:target_and_login){ OpsManager.target_and_login(target, username, password) }

      it 'should target' do
        expect(OpsManager).to receive(:target).with(target)
        target_and_login
      end

      it 'should login' do
        expect(OpsManager).to receive(:login).with(username, password)
        target_and_login
      end
    end

    describe 'when config does not have credentials' do
      subject(:target_and_login){ OpsManager.target_and_login(nil, nil, nil) }

      it 'should not target' do
        expect(OpsManager).not_to receive(:target).with(target)
        target_and_login
      end

      it 'should not login' do
        expect(OpsManager).not_to receive(:login).with(username, password)
        target_and_login
      end
    end
  end
end
