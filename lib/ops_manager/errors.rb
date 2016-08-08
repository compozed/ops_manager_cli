class OpsManager
  class UpgradeError < RuntimeError ; end
  class InstallationError < RuntimeError ; end
  class ProductDeploymentError < RuntimeError ; end
  class InstallationSettingsError < RuntimeError ; end
  class PivnetAuthenticationError < RuntimeError ; end
  class StemcellUploadError < RuntimeError ; end
  class ProductUploadError < RuntimeError ; end
end
