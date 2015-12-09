require "ops_manager_deployer/version"
require "ops_manager_deployer/vsphere"

class OpsManagerDeployer

  def initialize(conf_file)
    @conf_file = conf_file
  end

  def cloud
    return @cloud unless @cloud.nil?
    case provider
    when 'vsphere'
        @cloud ||= Vsphere.new cloud_opts
    end
  end

  private
  def provider
    cloud_config.fetch('provider')
  end

  def cloud_config
    @cloud_config ||= conf.fetch('cloud')
  end

  def cloud_opts
    @cloud_opts ||= cloud_config.fetch('opts')
  end

  def conf
    @conf ||= YAML.load_file(@conf_file)
  end
end
