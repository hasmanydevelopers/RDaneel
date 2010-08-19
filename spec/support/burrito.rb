require 'stringio'
require 'webrick'

class Burrito

  attr_reader :strio_log

  def initialize(port)
    @port = port
    @strio_log = StringIO.new
    access_log_stream = WEBrick::Log.new(@strio_log, WEBrick::Log::DEBUG)
    access_log = [[ access_log_stream, "[%s] %U" ]]
    webrick_logger = WEBrick::Log.new('/dev/null', WEBrick::Log::DEBUG)
    @server = WEBrick::HTTPServer.new(:Port => port,
                                      :Logger => webrick_logger,
                                      :AccessLog => access_log)
  end

  def start
    queue = Queue.new # synchronize the thread startup to the main thread
    @thread = Thread.new { queue << 1; @server.start }

    # wait for the queue
    value = queue.pop

    if !value
      STDERR.puts "Failed to startup test server!"
      exit(1)
    end

    trap("INT"){shutdown}
    at_exit{shutdown}
  end

  def shutdown
    begin
      @server.shutdown if @server
    rescue Object => e
      puts "Error #{__FILE__}:#{__LINE__}\n#{e.message}"
    end
  end

  def mount(opts)
    raise ":path is required" unless opts[:path]
    raise ":status is required" unless opts[:status]
    @server.mount_proc( opts[:path],
      lambda { |req, resp|
               resp.status = opts[:status]
               resp.body = opts[:body] if opts[:body]
               resp['Location'] = opts[:location] if opts[:location]
             } )
  end

  def served_requests
    strio = StringIO.new(@strio_log.string)
    result = []
    strio.each do |line|
      result << {:status => line[23,3].to_i,
                    :url => line[/\/.*/]}
    end
    result
  end
end

