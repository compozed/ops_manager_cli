class OpsManager
  module Api
    class Pivnet < OpsManager::Api::Base

      def get_product_releases(product_slug, opts = {})
        authenticated_get("/api/v2/products/#{product_slug}/releases", opts)
      end

      def accept_product_release_eula(product_slug, release_id)
        puts 'banana!!! !!'
        say_green("====> Accepting #{product_slug} release #{release_id} eula ...")
        authenticated_post("/api/v2/products/#{product_slug}/releases/#{release_id}/eula_acceptance")
      end

      def get_product_release_files(product_slug, release_id)
        authenticated_get("/api/v2/products/#{product_slug}/releases/#{release_id}/product_files")
      end

      def download_product_release_file(product_slug, release_id, file_id, opts = {})
        say_green "====> Downloading #{opts[:write_to]} stemcell ..."
        authenticated_post("/api/v2/products/#{product_slug}/releases/#{release_id}/product_files/#{file_id}/download", opts)
      end

      def get_authentication
        say_green "====> Authentication to Pivnet"
        res = authenticated_get("/api/v2/authentication")
        raise OpsManager::PivnetAuthenticationError.new(res.body) unless res.code == '200'
        res
      end

      private
      def target
        @target ||= "network.pivotal.io"
      end

      def authorization_header
        "Token #{pivnet_token}"
      end

      def pivnet_token
        @pivnet_token ||= OpsManager.get_conf(:pivnet_token)
      end
    end
  end
end
