class OpsManager
  class InstallationSettings < Hash
    def initialize(installation_settings_file)
      @installation_settings_file = installation_settings_file
      is = JSON.parse(File.read(@installation_settings_file))
      super.merge!(is)
    end

    def stemcells
      self.fetch('products').inject([]) do |a, p|
        a << {
          version: p['stemcell'].fetch('version'),
          file: p['stemcell'].fetch('file'),
        }
      end
    end
  end
end
