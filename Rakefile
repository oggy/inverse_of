require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "inverse_of"
    gem.summary = "Backport of ActiveRecord 2.3.6's inverse associations."
    gem.description = "Backport of ActiveRecord 2.3.6's inverse associations."
    gem.email = "george.ogata@gmail.com"
    gem.homepage = "http://github.com/oggy/inverse_of"
    gem.authors = ["George Ogata"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'

desc "Run the test/unit tests for inverse associations, backported from ActiveRecord 2.3.6."
Rake::TestTask.new(:test => :check_dependencies) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "inverse_of #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
