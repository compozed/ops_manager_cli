require "ops_manager/api"

class OpsManager::Deployment
  include OpsManager::API

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
    until( create_user(version).code.to_i == 200) do
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

  def new_vm_name
    @new_vm_name ||= "#{name}-#{version}"
  end

  private
  def current_vm_name
    @current_vm_name ||= "#{name}-#{current_version}"
  end
end
