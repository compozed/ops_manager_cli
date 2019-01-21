require 'fog/aws'
require 'ops_manager/appliance/base'

class OpsManager
  module Appliance
    class AWS < Base

      def deploy_vm
        server = connection.servers.create(
          block_device_mapping: [{
            'DeviceName'     => '/dev/xvda',
            'Ebs.VolumeSize' => config[:opts][:disk_size_in_gb],
          }],
          key_name: config[:opts][:ssh_keypair_name],
          flavor_id: config[:opts][:instance_type],
          subnet_id: config[:opts][:subnet_id],
          image_id: config[:opts][:image_id],
          private_ip_address: config[:ip],
          security_group_ids: security_group_ids,
          availability_zone: config[:opts][:availability_zone],
          iam_instance_profile_name: config[:opts][:instance_profile_name],
          tags: {
            'Name' => vm_name,
          }
        )
        server.wait_for { ready? }
        return server
      end

      def stop_current_vm(name)
        server = connection.servers.all("private-ip-address" => config[:ip], "tag:Name" => name).first
        if ! server
          fail "VM not found matching IP '#{config[:ip]}', named '#{name}'"
        end
        server.stop
        server.wait_for { server.state == "stopped" }

        # Create ami of stopped server
        response = connection.create_image(server.id, "#{name}-backup", "Backup of #{name}")
        image = connection.images.get( response.data[:body]['imageId'])
        image.wait_for(timeout=36000) { image.state == "available" }
        if image.state != "available"
          fail "Error creating backup AMI, bailing out before destroying the VM"
        end

        puts "Saved #{name} to AMI #{image.id} (#{name}-backup) for safe-keeping"

        server.destroy
        if !Fog.mocking?
          server.wait_for { server.state == 'terminated' }
        else
          # Fog's mock doesn't support transitioning state from terminating -> terminated
          # so we have to hack this here
          server.wait_for { server.state == 'terminating' }
        end
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
