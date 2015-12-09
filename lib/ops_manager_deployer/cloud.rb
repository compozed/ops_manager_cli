class OpsManagerDeployer::Cloud
  %w{ deploy downgrade upgrade }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end
end
