require "ops_manager/api/opsman"
require "ops_manager/api/pivnet"
require 'ops_manager/config/opsman_deployment'
require 'fileutils'

class OpsManager::ApplianceDeployment
  extend Forwardable
  attr_reader :config

  def_delegators :pivnet_api, :get_product_releases, :accept_product_release_eula,
    :get_product_release_files, :download_product_release_file
  def_delegators :opsman_api, :create_user, :get_installation_assets,
    :get_installation_settings, :get_diagnostic_report, :upload_installation_assets, :get_ensure_availability,
    :import_stemcell, :target, :password, :username, :ops_manager_version= , :reset_access_token, :get_pending_changes,
    :wait_for_https_alive

  attr_reader :config_file

  def initialize(config_file)
    @config_file = config_file
  end

  def run
    OpsManager.set_conf(:target, config[:ip])
    OpsManager.set_conf(:username, config[:username])
    OpsManager.set_conf(:password, config[:password])
    OpsManager.set_conf(:pivnet_token, config[:pivnet_token])


    case
    when current_version.empty?
      puts "No OpsManager deployed at #{config[:ip]}. Deploying ...".green
      deploy
      create_first_user
    when current_version < desired_version then
      puts "OpsManager at #{config[:ip]} version is #{current_version}. Upgrading to #{desired_version} .../".green
      upgrade
    when current_version == desired_version then
      if pending_changes?
        puts "OpsManager at #{config[:ip]} version has pending changes. Applying changes...".green
        if config[:single_tile_deploy]
          OpsManager::InstallationRunner.trigger!("deploy_products" => "none").wait_for_result
        else
          OpsManager::InstallationRunner.trigger!.wait_for_result
        end
      else
        puts "OpsManager at #{config[:ip]} version is already #{config[:desired_version]}. Skiping ...".green
      end
    end

    puts '====> Finish!'.green
  end

  def appliance 
    @appliance ||= if config[:provider] =~/vsphere/i
      OpsManager::Appliance::Vsphere.new(config)
    else
      OpsManager::Appliance::AWS.new(config)
    end
  end

  def create_first_user
    puts '====> Creating initial user'.green
    until( create_user.code.to_i == 200) do
      print ' .'.green ; sleep 1
    end
  end

  def deploy
    appliance.deploy_vm
    wait_for_https_alive 300
  end

  def upgrade
    get_installation_assets
    download_current_stemcells
    appliance.stop_current_vm(current_name)
    deploy
    upload_installation_assets
    wait_for_uaa
    provision_stemcells
    if config[:single_tile_deploy]
      OpsManager::InstallationRunner.trigger!("deploy_products" => "none").wait_for_result
    else
      OpsManager::InstallationRunner.trigger!.wait_for_result
    end
  end

  def list_current_stemcells
    JSON.parse(installation_settings).fetch('products').inject([]) do |a, p|
      product_name = "stemcells"
      if p['stemcell'].fetch('os') =~ /windows/i
        product_name = "stemcells-windows-server"
      end
      a << { version: p['stemcell'].fetch('version'), product: product_name }
    end.uniq
  end

  # Finds available stemcell's pivotal network release.
  # If it can not find the exact version it will try to find the newest minor version available.
  # #
  # @param version [String] the version number, eg: '2362.17'
  # @return release_id [Integer] the pivotal netowkr release id of the found stemcell.
  def find_stemcell_release(version, product_name)
    version  = OpsManager::Semver.new(version)
    releases = stemcell_releases(product_name).collect do |r|
      {
        release_id:  r['id'],
        version:     OpsManager::Semver.new(r['version']),
      }
    end
    releases.keep_if{ |r| r[:version].major == version.major }
    exact_version = releases.select {|r| r[:version] == version }
    return exact_version.first[:release_id] unless exact_version.empty?
    releases_sorted_by_version = releases.sort_by{ |r| r[:version].minor }.reverse
    return releases_sorted_by_version.first[:release_id] unless releases_sorted_by_version.empty?
  end

  # Finds stemcell's pivotal network release file.
  # #
  # @param release_id [String] the version number, eg: '2362.17'
  # @param filename [Regex] the version number, eg: /vsphere/
  # @return id and name [Array] the pivotal network file ID and Filename for the matching stemcell.
  def find_stemcell_file(release_id, filename, product_name)
    files = JSON.parse(get_product_release_files(product_name, release_id).body).fetch('product_files')
    file = files.select{ |r| r.fetch('aws_object_key') =~ filename }.first
    return file['id'], file['aws_object_key'].split('/')[-1]
  end

  # Lists all the available stemcells in the current installation_settings.
  # Downloads those stemcells.
  def download_current_stemcells
    print "====> Downloading existing stemcells ...".green
    puts "no stemcells found".green if list_current_stemcells.empty?
    FileUtils.mkdir_p current_stemcell_dir
    list_current_stemcells.each do |stemcell_info|
      stemcell_version = stemcell_info[:version]
      product_name = stemcell_info[:product]
      release_id = find_stemcell_release(stemcell_version, product_name)
      accept_product_release_eula(product_name, release_id)
      stemcell_regex = /vsphere/
      if config[:provider] == "AWS"
        stemcell_regex = /aws/
      end

      file_id, file_name = find_stemcell_file(release_id, stemcell_regex, product_name)
      download_product_release_file(product_name, release_id, file_id, write_to: "#{current_stemcell_dir}/#{file_name}")
    end
  end

  def new_vm_name
    @new_vm_name ||= "#{config[:name]}-#{config[:desired_version]}"
  end

  def current_version
    @current_version ||= OpsManager::Semver.new(version_from_diagnostic_report)
  end

  def current_name
    @current_name ||= "#{config[:name]}-#{current_version}"
  end

  def desired_version
    @desired_version ||= OpsManager::Semver.new(config[:desired_version])
  end

  def provision_stemcells
    reset_access_token
    Dir.glob("#{current_stemcell_dir}/*").each do |stemcell_filepath|
      import_stemcell(stemcell_filepath)
    end
  end

  def wait_for_uaa
    puts '====> Waiting for UAA to become available ...'.green
    while !uaa_available?
      sleep(5)
    end
  end

  private
  def uaa_available?
    res = get_ensure_availability
    res.code.eql? '302' and res.body.include? '/auth/cloudfoundry'
  end

  def diagnostic_report
    @diagnostic_report ||= get_diagnostic_report
  end

  def version_from_diagnostic_report
    return unless diagnostic_report
    version = parsed_diagnostic_report
      .fetch("versions")
      .fetch("release_version")
    version.gsub(/.0$/,'')
  end

  def parsed_diagnostic_report
    JSON.parse(diagnostic_report.body)
  end

  def current_vm_name
    @current_vm_name ||= "#{config[:name]}-#{current_version}"
  end


  def pivnet_api
    @pivnet_api ||= OpsManager::Api::Pivnet.new
  end

  def opsman_api
    @opsman_api ||= OpsManager::Api::Opsman.new
  end

  def config
    @config ||= OpsManager::Config::OpsmanDeployment.new(YAML.load_file(@config_file))
  end


  def desired_version?(version)
    !!(desired_version.to_s =~/#{version}/)
  end

  def installation_settings
    @installation_settings ||= get_installation_settings.body
  end

  def stemcell_releases(product_name)
    JSON.parse(get_product_releases(product_name).body).fetch('releases')
  end

  def current_stemcell_dir
    "/tmp/current_stemcells"
  end

  def pending_changes?
    !JSON.parse(get_pending_changes.body).fetch('product_changes').empty?
  end
end
