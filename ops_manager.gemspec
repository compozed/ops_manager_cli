# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ops_manager/version'

Gem::Specification.new do |spec|
  spec.name          = "ops_manager_cli"
  spec.version       = OpsManager::VERSION
  spec.authors       = ["CompoZed"]
  spec.email         = []

  spec.summary       = %q{ Performs Ops Manager deployments.  }
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "github_changelog_generator"
  spec.add_dependency "rbvmomi"
  spec.add_dependency "multipart-post"
  spec.add_dependency "clamp"
  spec.add_dependency "fog-aws"
  spec.add_dependency "net-ping"
  spec.add_dependency "cf-uaa-lib"
  spec.add_dependency "session_config"
  spec.add_dependency "rubysl-shellwords"
end
