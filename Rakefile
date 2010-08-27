require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rdaneel"
    gem.summary = %Q{Obey robots.txt on top of em-http-request (Asynchronous HTTP Client)}
    gem.description = %Q{Add robots.txt support on top of em-http-request}
    gem.email = ["edgargonzalez@gmail.com", "anibalrojas@gmail.com"]
    gem.homepage = "http://github.com/hasmanydevelopers/RDaneel"
    gem.authors = ["Edgar Gonzalez", "Anibal Rojas"]
    gem.add_dependency("em-http-request", ">= 0.2.11")
    gem.add_dependency('robot_rules', '>= 0.9.3')
    gem.add_development_dependency "cucumber", ">= 0.8.5"
    gem.add_development_dependency "relevance-rcov", ">= 0.9.2.1"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty" # Any valid command line option can go here.
  t.rcov = true
end

task :features => :check_dependencies

task :default => :features

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rdaneel #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

