class OpsManagerDeployer::Cloud
  %w{ deploy ommit upgrade }.each do |m|
    define_method(m) do
      raise NotImplementedError
    end
  end
end
