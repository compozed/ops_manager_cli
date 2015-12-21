class OpsManagerDeployer::Deployment
  attr_accessor :name, :ip, :username, :password, :opts

  def initialize(name, ip, username, password)
    @name, @ip, @username, @password = name, ip, username, password
  end
  %w{ deploy downgrade upgrade }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end


  def current_version
    @current_version ||= current_products.select{ |i| i.fetch('name') == 'microbosh' }
      .inject([]){ |r, i| r << i.fetch('product_version') }.sort.last
  rescue Errno::ETIMEDOUT
    nil
  end

  private
  def current_products
    @current_products ||= get_products
  end

  def current_vm_name
    @current_vm_name ||= "#{@name}-#{current_version}"
  end


  def get_products
    uri = URI.parse("https://#{@ip}/api/products")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    get = Net::HTTP::Get.new(uri.request_uri)

    get.basic_auth(@username, @password)
    res = JSON.parse(http.request(get).body)
    logger.info "products found: #{res}"
    return res
  end
end
