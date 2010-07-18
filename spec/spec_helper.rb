$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
require 'spec/autorun'
require 'webrick'

Spec::Runner.configure do |config|

end

class Burrito

  def initialize( options={:Port => 8080,}, &blk )
    @server = WEBrick::HTTPServer.new( options )
    @server_thread = Thread.new {
      blk.call(@server) if blk
      @server.start
    }
    @server
  end

  def mount( path, status, body = nil, blk = nil )
    @server.mount_proc( path, lambda { |req, resp|
                                       resp.status = status
                                       resp.body = body
                                       blk.call if blk
                                     } )
  end

  def unmount( path )
    @server.unmount( path )
  end

  def stop
    @server.shutdown
    @server_thread.join
  end

end

def should_be_hit( times = 1 )
  l = lambda {}
  m = l.should_receive(:call).exactly(times).times
  return l
end

