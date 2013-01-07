require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |spec|
    spec.pattern = 'spec/unit/*_spec.rb'
    spec.rspec_opts = ['--backtrace']
  end
  RSpec::Core::RakeTask.new(:integration) do |spec|
    spec.pattern = 'spec/integration/*_spec.rb'
    spec.rspec_opts = ['--backtrace']
  end
  task :all do
     Rake::Task['spec:unit'].execute
     Rake::Task['spec:integration'].execute
  end
end

task :default => 'spec:all'
