require 'spec_helper'
require 'ops_manager/api/pivnet'

describe OpsManager::Api::Pivnet do
  let(:pivnet_token){'abc123'}
  let(:stemcell_path){'abc123'}
  let(:pivnet){ described_class.new(silent: true) }

  before do
    OpsManager.set_conf(:pivnet_token, ENV['PIVNET_TOKEN'] || pivnet_token)
  end

  describe '#get_product_releases' do
    subject(:get_product_releases){ pivnet.get_product_releases(product_slug) }
    let(:uri){ "https://network.pivotal.io/api/v2/products/#{product_slug}/releases" }

    before do
      stub_request(:get, uri).to_return(status: 200, body: '{}', headers: {})
    end

    describe 'when correct product_slug is passed' do
      let(:product_slug){ 'stemcells-ubuntu-xenial' }

      it 'should run successfully' do
        get_product_releases
        expect(WebMock).to have_requested(:get, uri)
          .with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
      end
    end
  end

  describe '#accept_product_release_eula' do
    subject(:accept_product_release_eula){ pivnet.accept_product_release_eula(product_slug, release_id) }
    let(:uri){ "https://network.pivotal.io/api/v2/products/#{product_slug}/releases/#{release_id}/eula_acceptance" }

    before do
      stub_request(:post, uri).to_return(status: 200, body: '{}', headers: {})
    end

    describe 'when correct product_slug and release_id is passed' do
      let(:product_slug){ 'stemcells-ubuntu-xenial' }
      let(:release_id){ 1 }

      it 'should run successfully' do
        accept_product_release_eula
        expect(WebMock).to have_requested(:post, uri)
          .with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
      end
    end
  end

  describe '#get_product_release_files' do
    subject(:get_product_release_files){ pivnet.get_product_release_files(product_slug, release_id) }
    let(:uri){ "https://network.pivotal.io/api/v2/products/#{product_slug}/releases/#{release_id}/product_files" }

    before do
      stub_request(:get, uri).to_return(status: 200, body: '{}', headers: {})
    end

    describe 'when correct product_slug and release_id is passed' do
      let(:product_slug){ 'stemcells-ubuntu-xenial' }
      let(:release_id){ 1 }

      it 'should run successfully' do
        get_product_release_files
        expect(WebMock).to have_requested(:get, uri)
          .with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
      end
    end
  end

  describe '#download_product_release_file' do
    subject(:download_product_release_file){ pivnet.download_product_release_file(product_slug, release_id, file_id) }
    let(:uri){ "https://network.pivotal.io/api/v2/products/#{product_slug}/releases/#{release_id}/product_files/#{file_id}/download" }

    before do
      stub_request(:post, uri).to_return(status: 200, body: '{}', headers: {})
    end

    describe 'when correct product slug, release_id and file_id is passed' do
      let(:product_slug){ 'stemcells-ubuntu-xenial' }
      let(:release_id){ 1 }
      let(:file_id){ 1 }

      it 'should run successfully' do
        download_product_release_file
        expect(WebMock).to have_requested(:post, uri)
          .with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
      end
    end
  end
      # pivnet.download_stemcell(stemcell_version, stemcell_path, filename_regex)
      # expect(WebMock).to have_requested(

  describe '#get_authentication' do
    subject(:get_authentication){ pivnet.get_authentication }
    let(:uri){ "https://network.pivotal.io/api/v2/authentication" }

    before do
      stub_request(:get, 'https://network.pivotal.io/api/v2/authentication').
        to_return(status: status_code, body: "", headers: {})
    end

    describe 'when token is correct' do
      let(:pivnet_token){ 'good-token' }
      let(:status_code){ 200 }

      it 'should inform that token authenticates' do
        get_authentication
        expect(WebMock).to have_requested(:get, uri).
          with(:headers => { 'Authorization'=>"Token #{pivnet_token}" } )
      end
    end

    describe 'when token not is correct' do
      let(:pivnet_token){ 'wrong-token' }
      let(:status_code){ 401 }

      it 'should raise exception authentication fail' do
        expect do
          get_authentication
        end.to raise_exception(OpsManager::PivnetAuthenticationError)
      end
    end
  end

  # describe '#download_stemcell' do
    # let(:filename_regex){ /vsphere/ }
    # let(:stemcell_version){ "3146.10" }
    # let(:other_stemcell_version){ "3146.11" }
    # let(:product_file_id){ rand(1000..9999) }
    # let(:other_product_file_id){ rand(1000..9999) }
    # let(:release_id){ rand(1000..9999) }
    # let(:other_release_id){ rand(1000..9999) }



    # let(:stemcell_releases_response) do
      # {
        # 'releases' => [
          # {
            # 'id' => release_id,
            # 'version' => stemcell_version,
            # 'product_files' => {
              # 'href' => "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files"
            # }
          # },
          # {
            # 'id' => other_release_id,
            # 'version' => other_stemcell_version,
            # 'product_files' => {
              # 'href' => "https://network.pivotal.io/api/v2/products/stemcells/releases/#{other_release_id}/product_files"
            # }
          # }
        # ]
      # }
    # end

    # let(:product_files_response) do
      # {
        # "product_files" => [
          # {
            # "id"=> product_file_id,
            # "aws_object_key"=> "product_files/Pivotal-CF/bosh-stemcell-#{stemcell_version}-vsphere-esxi-ubuntu-trusty-go_agent.tgz",
            # "file_version"=> stemcell_version,
          # },
          # {
            # "id"=> other_stemcell_version,
            # "aws_object_key"=> "product_files/Pivotal-CF/bosh-stemcell-#{stemcell_version}-vcloud-esxi-ubuntu-trusty-go_agent.tgz",
            # "file_version"=> stemcell_version,
          # }
        # ]
      # }
    # end
    # let(:stemcell_path){ "bosh-stemcell-#{stemcell_version}-vsphere-esxi-ubuntu-trusty-go_agent.tgz" }
    # let(:stemcell_redirect_uri){ "https://abc123.cloudfront.net/product_files/Pivotal-CF/bosh-stemcell-3146.8-vsphere-esxi-ubuntu-trusty-go_agent.tgz" }

    # before do
      # stub_request(:get, 'https://network.pivotal.io/api/v2/products/stemcells/releases').
        # to_return(:status => 200, :body => stemcell_releases_response.to_json, :headers => {})

      # stub_request(:get, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files").
        # to_return(:status => 200, :body => product_files_response.to_json, :headers => {})

      # stub_request(:post, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download").
        # to_return(:status => 302, :body => "banana", :headers => { 'Location' => stemcell_redirect_uri })

      # stub_request(:get, stemcell_redirect_uri ).to_return(:status => 200, :body => "banana", :headers => {})

      # stub_request(:post, "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/eula_acceptance").
        # to_return(:status => 200, :body => "")

      # `rm #{stemcell_path}`
    # end

    # it 'should accept stemcell eula before downloading' do
      # pivnet.download_stemcell(stemcell_version, stemcell_path, filename_regex)
      # expect(WebMock).to have_requested(
        # :post,
        # "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/eula_acceptance").with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
    # end

    # it 'should download specified stemcell version' do
      # pivnet.download_stemcell(stemcell_version, stemcell_path, filename_regex)
      # expect(WebMock).to have_requested(
        # :post,
        # "https://network.pivotal.io/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download").with(:headers => { "Authorization"=>"Token #{pivnet_token}" })
    # end

      # after{ `rm #{stemcell_path}` }

    # it 'should write stemcell to file' do
      # `rm #{stemcell_path}`
      # pivnet.download_stemcell(stemcell_version, stemcell_path, filename_regex)
      # file_content = File.read(stemcell_path)
      # expect(file_content).to eq('banana')
    # end
  # end
end
