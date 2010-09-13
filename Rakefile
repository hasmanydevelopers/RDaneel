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
    gem.add_dependency("em-http-request", ">= 0.2.12")
    gem.add_dependency('robot_rules', '>= 0.9.3')
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "cucumber", ">= 0.8.5"
    gem.add_development_dependency "relevance-rcov", ">= 0.9.2.1"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'cucumber/rake/task'

desc "Run Cucumber features with RCov"
Cucumber::Rake::Task.new(:features_rcov) do |t|
  t.cucumber_opts = "--format pretty" # Any valid command line option can go here.
  t.rcov = true
  t.rcov_opts = %w{--exclude gems\/,spec\/,features\/ --aggregate coverage.data}
end

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty" # Any valid command line option can go here.
end


require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec_rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/*_spec.rb']
  spec.rcov = true
  spec.rcov_opts = %w{--exclude gems\/,spec\/,features\/ --aggregate coverage.data}
end

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/*_spec.rb']
end

desc "Run optional specs (internet access)"
Spec::Rake::SpecTask.new(:spec_optional) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/optional/*_spec.rb']
end

desc "Run both specs and features with RCov"
task :all_tests do |t|
  rm "coverage.data" if File.exist?("coverage.data")
  Rake::Task['spec_rcov'].invoke
  Rake::Task['features_rcov'].invoke
end

task :features => :check_dependencies
task :spec     => :check_dependencies
task :default  => :all_tests

