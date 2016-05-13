# Location: https://dtb5pzswcit1e.cloudfront.net/product_files/Pivotal-CF/bosh-stemcell-3146.8-vsphere-esxi-ubuntu-trusty-go_agent.tgz?Expires=1459175434&Signature=FbTSZ6MzrLOTLK-ScppomF2M2enRhtfLQDDXBSNT27hrVv1eW6Q%7EgAoewUjTc-xo1yY8SFG3GbmDOXGfYdGokEE20hHKyCQZoEkm-4vlLLNhU3nUp-BbI1Y6bXXy4Wi1IQiyWoOcG6sPr3IiGWZaNCYA8%7EiAqQNsYk8HTihMcKE_&Key-Pair-Id=APKAJLAM6FL65BYZP7UQ&filename=bosh-stemcell-3146.8-vsphere-esxi-ubuntu-trusty-go_agent.tgz
# Status: 302 Found
#
require 'spec_helper'
require 'ops_manager/api/base'

describe OpsManager::Api::Base do
  class FooApi < OpsManager::Api::Base; end

  let(:base_api){ FooApi.new }
  let(:desired_version){ '1.5' }
  let(:target){ 'foo.com' }
  let(:config){ double('config', desired_version: desired_version) }

  before do
   allow(base_api).to receive(:target).and_return(target)
   allow(base_api).to receive(:config).and_return(config)
  end

  describe '#post' do
    describe 'when response is 302' do
      let(:redirect_location){ 'https://other_site.com/file.txt' }

      before do
        stub_request(:post, 'https://foo.com/redirect').
          to_return(:status => 302, :body => "", :headers => { 'Location' => redirect_location })
      end

      it 'should redirect with get with same opts' do
        expect(base_api).to receive(:get).with(redirect_location, {some: 'opts'})
        base_api.post('/redirect', {some: 'opts'})
      end
    end
  end

  describe '#uri_for' do
    let(:uri){ base_api.uri_for(endpoint) }
    let(:endpoint){ '/some/endpoint' }

    it 'returns URI' do
      expect(uri).to be_kind_of(URI)
    end

    describe 'when endpoint is a full url' do
      let(:endpoint){ 'https://banana.com/get' }

      it 'does not override with target' do
        expect(uri.to_s).to eq(endpoint)
      end
    end

  end
end
