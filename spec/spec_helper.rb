$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

end

def start_server(options={}, &blk)
  @server = WEBrick::HTTPServer.new({:Port => 8080}.merge(options))
  @server_thread = Thread.new {
    blk.call(@server) if blk
    @server.start
  }
end

def stop_server
  @server.shutdown
  @server_thread.join
end

