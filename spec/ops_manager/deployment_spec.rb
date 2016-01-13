require 'spec_helper'
require 'yaml'
require "ops_manager/deployment"

describe OpsManager::Deployment do
  let(:name){ 'ops-manager' }
  let(:ip){ '1.2.3.4' }
  let(:username){ 'foo' }
  let(:password){ 'bar' }
  let(:base_uri){ 'https://foo:bar@1.2.3.4' }

  let(:deployment){ described_class.new(name, ip, username, password) }

  %w{ deploy downgrade upgrade }.each do |m|
    describe m do
      it 'should raise not implemented error'  do
        expect{ deployment.send(m) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe 'new' do
    %w{ name ip username password }.each do |p|
      it "should set #{p}" do
        expect(deployment.send(p)).to eq(send(p))
      end
    end
  end

  describe 'current_version' do
    describe 'when there is no ops manager' do
      before { allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ETIMEDOUT) }

      it 'should be nil' do
        expect(deployment.current_version).to be_nil
      end
    end
  end

  describe '#create_user' do
    before do
      allow(deployment).to receive(:new_version).and_return(new_version)
      stub_request(:post, uri).
        with(:body => body,
             :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})
    end

    describe 'when version 1.5.x' do
      let(:new_version){ '1.5.5.0' }
      let(:body){ "user[user_name]=foo&user[password]=bar&user[password_confirmantion]=bar"}
      let(:uri){ "#{base_uri}/api/users" }

      it "should successfully create first user" do
        VCR.turned_off do
          deployment.create_user
        end
      end
    end

    describe 'when version 1.6.x' do
      let(:new_version){ '1.6.4' }
      let(:uri){ "#{base_uri}/api/setup" }
      let(:body){ "setup[user_name]=foo&setup[password]=bar&setup[password_confirmantion]=bar&setup[eula_accepted]=true" }

      it "should successfully setup first user" do
        VCR.turned_off do
          deployment.create_user
        end
      end
    end
  end
end
