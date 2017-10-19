require 'fog/aws'

class OpsManager
  module Appliance
    class AWS
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def deploy_vm
        image_id = ::YAML.load_file(ami_mapping_file)[config[:opts][:region]]

        server = connection.servers.create(
          block_device_mapping: [{
            'DeviceName'     => '/dev/xvda',
            'Ebs.VolumeSize' => config[:opts][:disk_size_in_gb],
          }],
          key_name: config[:opts][:ssh_keypair_name],
          flavor_id: config[:opts][:instance_type],
          subnet_id: config[:opts][:subnet_id],
          image_id: image_id,
          private_ip_address: config[:ip],
          security_group_ids: security_group_ids,
          availability_zone: config[:opts][:availability_zone],
          iam_instance_profile_name: config[:opts][:instance_profile_name],
          tags: {
            'Name' => config[:name],
          }
        )
        server.wait_for { ready? }
        return server
      end

      private

      def ami_mapping_file
        Dir.glob(config[:opts][:ami_mapping_file]).first
      end

      def security_group_ids
        config[:opts][:security_groups].collect do |sg|
          connection.security_groups.get(sg).group_id
        end
      end

      def connection
        if config[:opts][:use_iam_profile]
          @connection ||= Fog::Compute.new({
            provider: config[:provider],
            use_iam_profile: config[:opts][:use_iam_profile],
            aws_access_key_id: "",
            aws_secret_access_key: "",
          })
        else
          @connection ||= Fog::Compute.new({
            provider: config[:provider],
            aws_access_key_id: config[:opts][:access_key],
            aws_secret_access_key: config[:opts][:secret_key],
          })
        end
      end
    end
  end
end
