require 'spec_helper'
require 'ops_manager/api/pivnet'

describe OpsManager::Api::Pivnet do
  let(:pivnet_token){'abc123'}
  let(:stemcell_path){'abc123'}
  let(:pivnet_api){ described_class.new }

  before do
    OpsManager.set_conf(:pivnet_token, ENV['PIVNET_TOKEN'] || pivnet_token)
      stub_request(:get, 'https://network.pivotal.io/api/v2/authentication')
    end

  describe '#new' do
    it  'should try authentication' do
      expect_any_instance_of(OpsManager::Api::Pivnet).to receive(:get_authentication)
      pivnet_api
    end
  end

  describe '#get_authentication' do
  before do
      stub_request(:get, 'https://network.pivotal.io/api/v2/authentication').
        to_return(:status => status_code, :body => "", :headers => {})
    end

    describe 'when token is correct' do
      let(:pivnet_token){ 'good-token' }
      let(:status_code){ 200 }


      it 'should inform that token authenticates' do
        VCR.turned_off do
          pivnet_api.get_authentication
          expect(WebMock).to have_requested(
            :get,
            "https://network.pivotal.io/api/v2/authentication").
            with(:headers => {'Accept'=>'*/*',
               'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
               'Authorization'=>"Token #{pivnet_token}",
               'User-Agent'=>'Ruby' } ).twice
        end
      end
    end

    describe 'when token not is correct' do
      let(:pivnet_token){ 'wrong-token' }
      let(:status_code){ 401 }

      it 'should raise exception authentication fail' do
        VCR.turned_off do
          expect do
            pivnet_api.get_authentication
            expect(WebMock).to have_requested(
              :get,
              "https://network.pivotal.io/api/v2/authentication").
              with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
          end.to raise_exception(OpsManager::PivnetAuthenticationError)
        end
      end
    end
  end

  describe '#download_stemcell' do
    let(:filename_regex){ /vsphere/ }
    let(:stemcell_version){ "3146.10" }
    let(:other_stemcell_version){ "3146.11" }
    let(:product_file_id){ rand(1000..9999) }
    let(:other_product_file_id){ rand(1000..9999) }
    let(:release_id){ rand(1000..9999) }
    let(:other_release_id){ rand(1000..9999) }



    let(:stemcell_releases_response) do
      {
        'releases' => [
          {
            'id' => release_id,
            'version' => stemcell_version,
            'product_files' => {
              'href' => "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files"
            }
          },
          {
            'id' => other_release_id,
            'version' => other_stemcell_version,
            'product_files' => {
              'href' => "https://network.pivotal.io/api/v2/products/stemcells/releases/#{other_release_id}/product_files"
            }
          }
        ]
      }
    end

    let(:product_files_response) do
      {
        "product_files" => [
          {
            "id"=> product_file_id,
            "aws_object_key"=> "product_files/Pivotal-CF/bosh-stemcell-#{stemcell_version}-vsphere-esxi-ubuntu-trusty-go_agent.tgz",
            "file_version"=> stemcell_version,
          },
          {
            "id"=> other_stemcell_version,
            "aws_object_key"=> "product_files/Pivotal-CF/bosh-stemcell-#{stemcell_version}-vcloud-esxi-ubuntu-trusty-go_agent.tgz",
            "file_version"=> stemcell_version,
          }
        ]
      }
    end
    let(:stemcell_path){ "bosh-stemcell-#{stemcell_version}-vsphere-esxi-ubuntu-trusty-go_agent.tgz" }
    let(:stemcell_redirect_uri){ "https://abc123.cloudfront.net/product_files/Pivotal-CF/bosh-stemcell-3146.8-vsphere-esxi-ubuntu-trusty-go_agent.tgz" }

    before do
      # curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token xo3saxf1AfjYxzrVNsa5" -X GET https://network.pivotal.io/api/v2/products/stemcells/releases
      stub_request(:get, 'https://network.pivotal.io/api/v2/products/stemcells/releases').
        to_return(:status => 200, :body => stemcell_releases_response.to_json, :headers => {})

      # curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token xo5saxf1AfjYxzrVNsa5" -X GET https://network.pivotal.io/api/v2/products/stemcells/releases/1562/product_files
      stub_request(:get, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files").
        to_return(:status => 200, :body => product_files_response.to_json, :headers => {})

        stub_request(:post, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download").
          to_return(:status => 302, :body => "banana", :headers => { 'Location' => stemcell_redirect_uri })

        stub_request(:get, stemcell_redirect_uri ).to_return(:status => 200, :body => "banana", :headers => {})
    end

    it 'should download specified stemcell version' do
      VCR.turned_off do
        pivnet_api.download_stemcell(stemcell_version, stemcell_path, filename_regex)
        expect(WebMock).to have_requested(
          :post,
          "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download").with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
      end
    end

    it 'should write stemcell to file' do
      VCR.turned_off do
        `rm #{stemcell_path}`
        pivnet_api.download_stemcell(stemcell_version, stemcell_path, filename_regex)
        file_content = File.read(stemcell_path)
        expect(file_content).to eq('banana')
      end
    end
  end
end
