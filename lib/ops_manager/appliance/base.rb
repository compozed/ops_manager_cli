
class OpsManager
  module Appliance
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
      end
      def deploy_vm
        raise NotImplementedError.new("You must implement deploy_vm.")
      end
      def stop_current_vm(name)
        raise NotImplementedError.new("You must implement stop_current_vm.")
      end

      private
      def vm_name
        @vm_name ||= "#{config[:name]}-#{config[:desired_version]}"
      end
    end
  end
end
