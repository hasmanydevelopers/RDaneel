$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rdaneel'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

end

def start_server(options={}, &blk)
  # disable logging
  webrick_log_file = '/dev/null'
  webrick_logger = WEBrick::Log.new(webrick_log_file, WEBrick::Log::INFO)
  access_log_stream = webrick_logger
  access_log = [[ access_log_stream, WEBrick::AccessLog::COMBINED_LOG_FORMAT ]]
  @server = WEBrick::HTTPServer.new({
    :Port => 8080,
    :Logger => webrick_logger,
    :AccessLog => access_log
    }.merge(options))
  @server_thread = Thread.new {
    blk.call(@server) if blk
    @server.start
  }
end

def stop_server
  @server.shutdown
  @server_thread.join
end

