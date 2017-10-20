require 'ostruct'

class OpsManager
  module Config
    class Base < OpenStruct
      def initialize(config)
        super(config.to_symbolize)
      end

      def validate_presence_of!(*attrs)
        attrs.each do |attr|
          raise "missing #{attr} on config" unless self.to_h.has_key?(attr)
        end
      end

      def expand_path_for!(*attrs)
        attrs.each do |attr|
          path = self[attr] 
          self[attr] = if path =~ %r{^file://}
            path = Dir.glob(path.gsub!('file://','')).first
            "file://#{path}"
          else
            Dir.glob(path).first
          end
        end
      end
    end
  end
end

class Hash 
  def to_symbolize
      Hash[self.map do |k, v| 
      if v.kind_of?(Hash) 
        [k.to_sym, v.to_symbolize]
      else
        [k.to_sym, v]
      end
    end]
  end
end

