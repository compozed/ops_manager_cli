require "clamp"
class OpsManager
  class Cli < Clamp::Command

    class Deploy < Clamp::Command
      option "--config", "CONFIG", "Configuration File", required: true

      def execute
        OpsManager.new(config).deploy
      end
    end

    subcommand "deploy", "deploy ops_manager" , Deploy
  end
end
