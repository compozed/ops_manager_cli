require 'ostruct'

class OpsManager
  class Configs
    class Base < OpenStruct
      def initialize(config)
        @config = config
        super(config)
      end

      def validate_presence_of!(*present_attrs)
        present_attrs.map!(&:to_s).each do |attr|
          raise "missing #{attr} on config" unless @config.has_key?(attr)
        end
      end

      def filepath
        find_full_path(@config['filepath'])
      end

        def find_full_path(filepath)
        `find #{filepath}`.split("\n").first
        end
    end
  end
end
