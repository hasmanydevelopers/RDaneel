$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
require 'webrick'

Spec::Runner.configure do |config|
  config.before :suite do
    burrito
  end
  config.after :suite do
    burrito.stop
  end
end

def burrito
  Thread.current[:burrito] ||= Burrito.new
end

class Burrito

  def initialize( options={}, &blk )
    webrick_log_file = '/dev/null'  # disable logging
    webrick_logger = WEBrick::Log.new(webrick_log_file, WEBrick::Log::DEBUG)
    access_log_stream = webrick_logger
    access_log = [[ access_log_stream, WEBrick::AccessLog::COMBINED_LOG_FORMAT ]]
    default_opts = {:Port => 8080, :Logger => webrick_logger, :AccessLog => access_log }
    @server = WEBrick::HTTPServer.new( default_opts.merge(options) )
    @server_thread = Thread.new {
      blk.call(@server) if blk
      @server.start
    }
    @server
  end

  def mount( opts )
    raise ":path is required" if opts[:path].nil?
    raise ":status is required" if opts[:status].nil?
    @server.mount_proc( opts[:path],
      lambda { |req, resp|
               resp.status = opts[:status]
               resp.body = opts[:body] unless opts[:body].nil?
               resp['Location'] = opts[:location] unless opts[:location].nil?
               opts[:block].call unless opts[:block].nil?
             } )
  end

  def stop
    @server.shutdown
    @server_thread.join
  end

  def unmount(path)
    @server.unmount(path)
  end

end

def should_not_be_hit
  should_be_hit( 0 )
end

def should_be_hit_once
  should_be_hit( 1 )
end

def should_be_hit_twice
  should_be_hit( 2 )
end

def should_be_hit( times = 1 )
  l = lambda {}
  m = l.should_receive(:call).exactly(times).times
  return l
end

