require 'spec_helper'
require 'ops_manager/api'

class Dummy
  include OpsManager::API

  def get_banana
    get('/banana')
  end
end

describe OpsManager::API do
  let(:dummy){ Dummy.new }
  let(:target){ '1.2.3.4' }
  let(:username){'foo' }
  let(:password){ 'bar' }

  before(:all){ VCR.turn_off! }
  after(:all){ VCR.turn_on! }

  before do
    OpsManager.target(target)
    OpsManager.login(username, password)
  end

  describe '#get' do
    let(:url){ "https://#{username}:#{password}@#{target}/banana" }

    it 'performs a call with basic auth' do
      stub_request(:get, url).
        to_return(:status => 200, :body => "", :headers => {})
      dummy.get_banana
      expect(WebMock).to have_requested(:get, url).once
    end
  end

  describe "#post"
  describe "#post_multipart"
end

