$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
require 'spec/autorun'
require 'webrick'

Spec::Runner.configure do |config|

end

def mount( path, status, body = nil )
  @server.mount_proc( path, lambda { |req, resp|
                                     resp.status = status
                                     resp.body = body } )
end

def start_server( options={:Port => 8080,}, &blk )
  @server = WEBrick::HTTPServer.new( options )
  @server_thread = Thread.new {
    blk.call(@server) if blk
    @server.start
  }
end

def stop_server
  @server.shutdown
  @server_thread.join
end

