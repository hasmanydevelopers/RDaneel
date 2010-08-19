$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

Spec::Runner.configure do |config|
  config.before :suite do
    puts "\e[4mThese specs could take a while, please be patience\e[0m"
  end
end

