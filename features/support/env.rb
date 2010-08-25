$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'burrito'



unless $server
  $server = Burrito.new
  $server.start
end

Before do
  $server.reset
end

at_exit do
  $server.shutdown
end

