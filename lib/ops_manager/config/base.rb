require 'ostruct'

class OpsManager
  module Config
    class Base < OpenStruct

      def initialize(config)
        super(config)
      end

      def validate_presence_of!(*attrs)
        attrs.each do |attr|
          raise "missing #{attr} on config" unless self.to_h.has_key?(attr)
        end
      end

      def expand_path_for!(*attrs)
        attrs.each do |attr|
          self[attr] = Dir.glob(self[attr]).first
        end
      end
    end
  end
end
