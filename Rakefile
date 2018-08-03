require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'github_changelog_generator/task'

RSpec::Core::RakeTask.new(:spec)

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.max_issues = 50
end

task :default => :spec
task :release => :changelog
