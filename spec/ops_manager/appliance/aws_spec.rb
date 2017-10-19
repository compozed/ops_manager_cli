require 'spec_helper'

describe OpsManager::Appliance::AWS do
  let!(:aws){ described_class.new(config) }
  let!(:connection) do
    Fog::Compute.new({
      provider: 'AWS',
      aws_access_key_id: 'key',
      aws_secret_access_key: 'secret'
    })
  end
  let!(:config) do
    {
      name: 'ops-manager-aws',
      provider: 'AWS',
      desired_version: '1.4.11.0',
      ip: '10.0.2.24',
      admin_username: 'admin',
      admin_password: 'admin',
      opts: {
        region: 'us-east-1',
        availability_zone: 'us-east-1b',
        ami_mapping_file: 'ami/*.yml',
        instance_type: 'm4.medium',
        ssh_keypair_name: keypair_name,
        security_groups: ['sec-group-1','sec-group-2'],
        subnet_id: subnet_id,
        disk_size_in_gb: '100',
        instance_profile_name: 'opsman-profile',

        access_key: 'key',
        secret_key: 'secret',
      }
    }
  end
  let(:ops_manager_ami) do
  end

  let!(:keypair_name) do
    connection.key_pairs.create(name: "test-keypair").name
  end

  let!(:vpc_id) do
    connection.create_vpc('10.0.0.0/8').data[:body]['vpcSet'][0]['vpcId']
  end
  let!(:subnet_id) do
    connection.create_subnet(vpc_id, '10.0.2.0/24', {
      AvailabilityZone: 'us-east-1b',
    }).data[:body]['subnet']['subnetId']
  end
  let!(:security_groups_ids) do
    config[:opts][:security_groups].collect do |sg|
      connection.create_security_group(sg,sg, vpc_id).data[:body]['groupId']
    end
  end

  before(:all) do
    Fog.mock!
  end
  after(:each) do
    Fog::Mock.reset
  end

  describe '#deploy_vm' do
    it 'should create a vm with the proper config' do
      server = nil

      expect do
        server = aws.deploy_vm
      end.to change{ connection.servers.count }.from(0).to(1)

      expect(server.tags["Name"]).to eq(config[:name])
      expect(server.flavor_id).to eq(config[:opts][:instance_type])
      expect(server.subnet_id).to eq(config[:opts][:subnet_id])
      expect(server.key_name).to eq(config[:opts][:ssh_keypair_name])
      expect(server.private_ip_address).to eq(config[:ip])
      expect(server.associate_public_ip).to eq(false)
      expect(server.availability_zone).to eq(config[:opts][:availability_zone])
      expect(server.image_id).to eq('ami-a26bacd8')
      disk = connection.volumes.get(server.block_device_mapping[0]["volumeId"])
      expect(disk.size).to eq(config[:opts][:disk_size_in_gb])

      # These tests fail due to bugs in the Fog Mock:
      #  https://github.com/fog/fog-aws/issues/404
      skip "Cannot test security groups, instance profiles, vpc id, or lack of public IP due to https://github.com/fog/fog-aws/issues/404" do
        expect(server.security_group_ids).to eq(security_groups_ids)
        expect(server.iam_instance_profile["arn"]).to end_with(":instance-profile/#{config[:opts][:instance_profile_name]}")
        expect(server.vpc_id).to eq(vpc_id)
        expect(server.public_ip_address).to be_nil
      end
    end
  end

  describe '#deploy vm using instance profiles' do
    let!(:connection) do
      Fog::Compute.new({
        provider: "AWS",
        use_iam_role: true,
        aws_access_key_id: "",
        aws_secret_access_key: "",
      })
    end
    it 'should use instance profile roles rather than a keypair, if provided' do
      config[:opts][:use_iam_profile] = true
      config[:opts][:access_key] = ""
      config[:opts][:secret_key] = ""
      expect do
        server = aws.deploy_vm
      end.to change{ connection.servers.count}. from(connection.servers.count).to(connection.servers.count + 1)

      expect(aws.instance_eval { @connection.instance_eval { @use_iam_profile }}).to eq(true)
    end
  end

  describe '#stop_current_vm' do
    # stop vm, don't terminate/delete
    # ensure IP is released though, so new VMs can come online
    # want to keep it around as an artifact for failure scenarios
  end
end
