require "ops_manager_deployer/version"
require "ops_manager_deployer/vsphere"
require "net/https"
require "uri"
require "json"
require "yaml"

class OpsManagerDeployer
  attr_writer :cloud

  def initialize(conf_file)
    @conf_file = conf_file
  end

  def cloud
    return @cloud unless @cloud.nil?
    case provider
    when 'vsphere'
      @cloud = Vsphere.new(conf.fetch('ip'), conf.fetch('username'), conf.fetch('password'), cloud_opts)
    end
  end

  def run
      case
      when current_version.nil?
        puts "No OpsManager deployed at #{conf.fetch('ip')}. Deploying ..."
        cloud.deploy
      when current_version < new_version then
        puts "OpsManager at #{conf.fetch('ip')} version is #{current_version}. Upgrading to #{new_version}.../"
        cloud.upgrade
      else
        puts "OpsManager at #{conf.fetch('ip')} version is already #{new_version}. Skiping ..."
      end
  end

  def current_version
    current_products.select{ |i| i.fetch('name') == 'microbosh' }
      .inject([]){ |r, i| r << i.fetch('product_version') }.sort.last
  rescue Errno::ETIMEDOUT
    nil
  end


  def new_version
    cloud_opts.fetch('version')
  end

  private
  def current_products
    uri = URI.parse("https://#{conf.fetch('ip')}/api/products")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    get = Net::HTTP::Get.new(uri.request_uri)

    get.basic_auth(conf.fetch('username'), conf.fetch('password'))
    JSON.parse(http.request(get).body)
  end

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
    @conf ||= ::YAML.load_file(@conf_file)
  end
end
