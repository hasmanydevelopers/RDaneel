$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
require 'webrick'

# keep webrick quiet
class ::WEBrick::HTTPServer
  def access_log(config, req, res)
    # nop
  end
end
class ::WEBrick::BasicLog
  def log(level, data)
    # nop
  end
end

def locked_file
  File.join(File.dirname(__FILE__),"server_lock-#{@__port}")
end

def server_setup(port=8080, &blk)
  @__port = port
  if @server.nil? and !File.exist?(locked_file)
    File.open(locked_file,'w') {|f| f << 'locked' }
    @server = WEBrick::HTTPServer.new :Port => port
    blk.call(@server) if blk
    queue = Queue.new # synchronize the thread startup to the main thread
    @test_thread = Thread.new { queue << 1; @server.start }

    # wait for the queue
    value = queue.pop

    if !value
      STDERR.puts "Failed to startup test server!"
      exit(1)
    end

    trap("INT"){server_shutdown}
    at_exit{server_shutdown}
  end
end

def server_shutdown
  begin
    if File.exist?(locked_file)
      File.unlink locked_file
      @server.shutdown unless @server.nil?
      @server = nil
    end
  rescue Object => e
    puts "Error #{__FILE__}:#{__LINE__}\n#{e.message}"
  end
end

def mount(server, opts)
  raise ":path is required" if opts[:path].nil?
  raise ":status is required" if opts[:status].nil?
  server.mount_proc( opts[:path],
    lambda { |req, resp|
             resp.status = opts[:status]
             resp.body = opts[:body] unless opts[:body].nil?
             resp['Location'] = opts[:location] unless opts[:location].nil?
             opts[:block].call unless opts[:block].nil?
           } )
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

Spec::Runner.configure do |config|
end

