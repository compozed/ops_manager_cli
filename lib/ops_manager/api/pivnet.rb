class OpsManager
  module Api
    class Pivnet
      include OpsManager::Api::Base

      def initialize
        get_authentication
      end

      def download_stemcell(stemcell_version, stemcell_path, filename_regex)
        puts "====> Downloading stemcell #{ stemcell_path }...".green

        release_id = get_release_for(stemcell_version).fetch('id')
        product_file = get_product_file_for(release_id, filename_regex)
        product_file_id = product_file.fetch('id')

        accept_release_eula(release_id)
        download_product(release_id, product_file_id, stemcell_path)
      end

      def get_authentication
        puts "====> Authentication to Pivnet".green
        opts = { headers: { 'Authorization' => "Token #{pivnet_token}" } }
        res = get("/api/v2/authentication", opts)
        raise OpsManager::PivnetAuthenticationError.new(res.body) unless res.code == '200'
        res
      end

      private

      def accept_release_eula(release_id)
        puts "====> Accepting stemcell eula ...".green

        opts = { headers: { 'Authorization' => "Token #{pivnet_token}" } }
        post("/api/v2/products/stemcells/releases/#{release_id}/eula_acceptance", opts)
      end

      def download_product(release_id, product_file_id, stemcell_path)
        opts = { write_to: stemcell_path, headers: { 'Authorization' => "Token #{pivnet_token}" } }
        post("/api/v2/products/stemcells/releases/#{release_id}/product_files/#{product_file_id}/download", opts)
      end

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

      def pivnet_token
        @pivnet_token ||= OpsManager.get_conf(:pivnet_token)
      end
    end
  end
end
