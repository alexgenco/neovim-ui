require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :example do
  Dir[File.expand_path("../examples/*.rb", __FILE__)].each do |example_path|
    basename = File.basename(example_path, ".rb")

    desc "Run examples/#{basename}.rb"
    task basename do
      ruby "-I", File.expand_path("../lib", __FILE__), example_path
    end
  end
end

task :default => :spec
