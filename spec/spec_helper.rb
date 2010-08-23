$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

$server = Burrito.new
$server.start  
