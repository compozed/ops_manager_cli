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

  describe '@show_status' do
    let(:token){ 'valid token' }

    before do
      described_class.set_conf(:target, target)
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_token).and_return(token)
    end

    it 'shows target endpoint' do
      expect(described_class.show_status).to match(/Target: .+1.2.3.4/)
    end

    describe 'when credentials are correct' do
      let(:token){ 'valid token' }

      it 'shows target endpoint' do
        expect(described_class.show_status).to match(/Authenticated: .+YES/)
      end
    end


    describe 'when credentials are incorrect' do
      let(:token){ nil }

      it 'should let the user know he is not authenticated' do
        expect(described_class.show_status).to match(/Authenticated: .+NO/)
      end
    end
  end

  describe '@set_target' do
    let(:net_ping){ double(ping?: pingable?) }
    subject(:set_target){ OpsManager.set_target(target) }

    before do
      OpsManager.set_conf(:target, nil)
      allow(Net::Ping::HTTP).to receive(:new).with("https://#{target}/docs").and_return(net_ping)
    end

    describe 'when target is pingable' do
      let(:pingable?){ true }

      it 'should set conf target' do
        expect do
          set_target
        end.to change{ OpsManager.get_conf :target }.from(nil).to(target)
      end
    end

    describe 'when target is not pingable' do
      let(:pingable?){ false }

      it 'should set conf target' do
        expect do
          set_target
        end.not_to change{ OpsManager.get_conf :target }
      end
    end
  end

  describe '@login' do
    let(:opsman_api){ double.as_null_object }
    subject(:login){ OpsManager.login('foo', 'bar') }

    before do
      allow(OpsManager::Api::Opsman).to receive(:new).and_return(opsman_api)
    end

    it 'should set conf username' do
      expect do
        login
      end.to change{ OpsManager.get_conf :username }
    end

    it 'should set conf password' do
      expect do
        login
      end.to change{ OpsManager.get_conf :password }
    end

    it 'should try to get uaa token' do
      expect(opsman_api).to receive(:get_token)
      login
    end
  end

  describe '@deployment=' do
    it 'should set deployment config file path' do
      expect do
        OpsManager.deployment= 'path/to/config'
      end.to change{ OpsManager.get_conf :deployment }
    end
  end

  describe '@deployment=' do
    it 'should set deployment config file path' do
      expect do
        OpsManager.deployment= 'path/to/config'
      end.to change{ OpsManager.get_conf :deployment }
    end
  end

  describe '@target_and_login' do
    before do
      allow(OpsManager).to receive(:set_target)
      allow(OpsManager).to receive(:login)
    end

    describe 'when config has credentials' do
      subject(:target_and_login){ OpsManager.target_and_login(target, username, password) }

      it 'should target' do
        expect(OpsManager).to receive(:set_target).with(target)
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
        expect(OpsManager).not_to receive(target).with(target)
        target_and_login
      end

      it 'should not login' do
        expect(OpsManager).not_to receive(:login).with(username, password)
        target_and_login
      end
    end
  end
end
