require 'spec_helper'
require 'ops_manager/pivnet_api'

describe OpsManager::PivnetApi do
  let(:token){'abc123'}
  let(:stemcell_path){'abc123'}
  let(:pivnet_api){ described_class.new(token) }

  describe '#new' do
    it 'should set pivnet token' do
      expect(pivnet_api.token).to eq(token)
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

    before do
      # curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token xo3saxf1AfjYxzrVNsa5" -X GET https://network.pivotal.io/api/v2/products/stemcells/releases
      stub_request(:get, 'https://network.pivotal.io/api/v2/products/stemcells/releases').
        to_return(:status => 200, :body => stemcell_releases_response.to_json, :headers => {})

      # curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token xo5saxf1AfjYxzrVNsa5" -X GET https://network.pivotal.io/api/v2/products/stemcells/releases/1562/product_files
        stub_request(:get, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files").
          to_return(:status => 200, :body => product_files_response.to_json, :headers => {})

        stub_request(:get, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download").
          to_return(:status => 200, :body => "banana", :headers => {})
    end

    it 'should download specified stemcell version' do
      VCR.turned_off do
        pivnet_api.download_stemcell(stemcell_version, stemcell_path, filename_regex)
        expect(WebMock).to have_requested(
          :get,
          "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download").with(:headers => { "Authorization"=>"Token #{token}" })
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
