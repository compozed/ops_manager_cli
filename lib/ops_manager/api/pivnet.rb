class OpsManager
  module Api
    class Pivnet < OpsManager::Api::Base

      def initialize
        get_authentication
      end

      def download_stemcell(version, filepath, filename_regex)
        product_slug = 'stemcells'
        puts "====> Downloading #{product_slug} #{filepath}...".green

        release_id = get_release(product_slug , version).fetch('id')
        product_file = get_product_file(product_slug, release_id, filename_regex)
        product_file_id = product_file.fetch('id')

        accept_release_eula(product_slug, release_id)
        download_product(product_slug, release_id, product_file_id, filepath)
      end

      def get_authentication
        puts "====> Authentication to Pivnet".green
        opts = { headers: { 'Authorization' => "Token #{pivnet_token}" } }
        res = get("/api/v2/authentication", opts)
        raise OpsManager::PivnetAuthenticationError.new(res.body) unless res.code == '200'
        res
      end

      private

      def accept_release_eula(product_slug, release_id)
        puts "====> Accepting #{product_slug} release #{release_id} eula ...".green
        opts = { headers: { 'Authorization' => "Token #{pivnet_token}" } }
        post("/api/v2/products/#{product_slug}/releases/#{release_id}/eula_acceptance", opts)
      end

      def download_product(product_slug, release_id, product_file_id, filepath)
        opts = { write_to: filepath, headers: { 'Authorization' => "Token #{pivnet_token}" } }
        post("/api/v2/products/#{product_slug}/releases/#{release_id}/product_files/#{product_file_id}/download", opts)
      end

      def get_product_releases(product_slug, opts = {})
        get("/api/v2/products/#{product_slug}/releases", opts)
      end

      def get_product_files(product_slug, release_id, opts = {})
        get("/api/v2/products/#{product_slug}/releases/#{release_id}/product_files",opts)
      end

      def get_release(product_slug, version)
        releases = JSON.parse(get_product_releases(product_slug).body).fetch('releases')
        releases.select{ |r| r.fetch('version') == version }.first
      end

      def get_product_file(product_slug, release_id, filename_regex)
        products = JSON.parse(get_product_files(product_slug, release_id).body).fetch('product_files')
        products.select{ |r| r.fetch('aws_object_key') =~ filename_regex }.first
      end

      def target
        @target ||= "network.pivotal.io"
      end

      def pivnet_token
        @pivnet_token ||= OpsManager.get_conf(:pivnet_token)
      end
    end
  end
end
