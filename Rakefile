require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'github_changelog_generator/task'

RSpec::Core::RakeTask.new(:spec)

GitHubChangelogGenerator::RakeTask.new(:changelog)

task :default => :spec
task :release => :changelog
