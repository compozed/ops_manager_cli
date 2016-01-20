require 'spec_helper'
require 'ops_manager/api'

describe OpsManager::API do
  let(:api){ described_class.new(target, username, password) }
  let(:target){ '1.2.3.4' }
  let(:username){'foo' }
  let(:password){ 'bar' }

  before(:all){ VCR.turn_off! }
  after(:all){ VCR.turn_on! }

  describe "#initialize" do
    %w(target username password).each do |attr|
      it "sets the #{attr}" do
        expect(api.send(attr)).to eq(send(attr))
      end
    end
  end

  describe '#get' do
    let(:url){ "https://#{username}:#{password}@#{target}/banana" }

    it 'performs a call with basic auth' do
      stub_request(:get, url).
        to_return(:status => 200, :body => "", :headers => {})
      api.get('/banana')
      expect(WebMock).to have_requested(:get, url).once
    end
  end

  describe "#post"
  describe "#post_multipart"
end

