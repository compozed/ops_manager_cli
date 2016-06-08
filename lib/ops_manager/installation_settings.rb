class OpsManager
  class InstallationSettings < Hash
    def initialize(parsed_installation_settings)
      super.merge!(parsed_installation_settings)
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
