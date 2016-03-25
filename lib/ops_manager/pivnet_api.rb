class OpsManager
  class PivnetApi
    include OpsManager::BaseApi
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def download_stemcell(stemcell_version, stemcell_path, filename_regex)
      opts = {token: token}

      release_id = get_release_for(stemcell_version).fetch('id')
      product_file = get_product_file_for(release_id, filename_regex)
      product_file_id = product_file.fetch('id')

      opts.merge!(write_to: stemcell_path)
      get("/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download", opts)
    end

    private

    def target
      @target ||= "network.pivotal.io"
    end

    def get_stemcell_releases(opts = {})
      get("/api/v2/products/stemcells/releases", opts)
    end

    def get_product_files(release_id, opts = {})
      get("/api/v2/products/stemcells/releases/#{release_id}/product_files",opts)
    end

    def get_release_for(stemcell_version)
      releases = JSON.parse(get_stemcell_releases.body).fetch('releases')
      releases.select{ |r| r.fetch('version') == stemcell_version }.first
    end

    def get_product_file_for(release_id, filename_regex)
      products = JSON.parse(get_product_files(release_id).body).fetch('product_files')
      products.select{ |r| r.fetch('aws_object_key') =~ filename_regex }.first
    end
  end
end
