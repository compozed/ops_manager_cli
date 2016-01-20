require "ops_manager/api"

class OpsManager::Deployment
  attr_accessor :name, :version

  def initialize(name,  version)
    @name, @version = name, version
  end

  %w{ stop_current_vm deploy_vm }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end

  def deploy
    deploy_vm
    create_first_user
  end

  def create_first_user
    puts '====> Creating initial user...'.green
    until( create_user.code.to_i == 200) do
      print '.'.green ; sleep 1
    end
  end

  def upgrade
    get_installation_assets
    get_installation_settings
    stop_current_vm
    deploy
    upload_installation_assets
    puts "====> Finish!".green
  end


  def get_installation_assets
    puts '====> Download installation assets...'.green
    api.get("/api/installation_asset_collection",
       write_to: "installation_assets.zip")
  end

  def upload_installation_assets
    puts '====> Uploading installation assets...'.green
    zip = UploadIO.new("#{Dir.pwd}/installation_assets.zip", 'application/x-zip-compressed')
    api.multipart_post( "/api/installation_asset_collection",
      :password => @password,
      "installation[file]" => zip
    )
  end

  def get_installation_settings
    puts '====> Downloading installation settings...'.green
    api.get("/api/installation_settings",
       write_to: "installation_settings.json")
  end

  def current_version
    @current_version ||= current_products.select{ |i| i.fetch('name') == 'microbosh' }
      .inject([]){ |r, i| r << i.fetch('product_version') }.sort.last
  rescue Errno::ETIMEDOUT
    nil
  end

  def new_vm_name
    @new_vm_name ||= "#{@name}-#{@version}"
  end

  def create_user
    if version =~/1.5/
      body= "user[user_name]=#{username}&user[password]=#{password}&user[password_confirmantion]=#{password}"
      uri= "/api/users"
    elsif version=~/1.6/
      body= "setup[user_name]=#{username}&setup[password]=#{password}&setup[password_confirmantion]=#{password}&setup[eula_accepted]=true"
      uri= "/api/setup"
    end

    res = api.post(uri, body: body)
    res
  end

  private
    def target
      @target ||= OpsManager.get_conf(:target)
    end

    def username
      @username ||= OpsManager.get_conf(:username)
    end

    def password
      @password ||= OpsManager.get_conf(:password)
    end
  def current_products
    @current_products ||= JSON.parse(api.get("/api/products").body)
    return @current_products
  end

  def current_vm_name
    @current_vm_name ||= "#{@name}-#{current_version}"
  end

  def api
    @api ||= OpsManager::API.new(target, username, password)
  end
end
