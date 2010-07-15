require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'webrick'


module EventMachine
  class HttpClient < Connection
    attr_accessor :redirects_count
  end
end

describe "RDaneel" do

  describe "when there is no robots.txt" do
    before(:all) do
      start_server do |s|
        s.mount_proc('/hello_world', lambda { |req, resp| resp.status = 200; resp.body = "hello world"})
        s.mount_proc('/redirect', lambda { |req, resp| resp.status = 301; resp['Location'] = "http://127.0.0.1:8080/hello_world"})
        s.mount_proc('/redirect1', lambda { |req, resp| resp.status = 301; resp['Location'] = "http://127.0.0.1:8080/redirect"})
      end
    end

    after(:all) do
      stop_server
    end

    it "should follow and get the uri" do
      EM.run {

        http = EM::HttpRequest.new("http://127.0.0.1:8080/redirect1").get

t = 0

lam = lambda {|http|
    puts "handle_redirect"
    if http.response_header.status == 200
      puts "Exitoso"
      EM.stop
    elsif http.response_header.status == 301
      puts t+=1
      puts http.response_header.location
      redirect = EM::HttpRequest.new(http.response_header.location).get
      redirect.callback(&lam)
      redirect.errback do
        EM.stop
      end
    else
      puts "No se que paso: #{http.error} - #{http.response_header.status}"
      EM.stop
    end
  }



        http.callback(&lam)
        http.errback do
          EM.stop
        end
      }
    end
  end
end

def _handle_redirect
  lambda {|http|
    puts "handle_redirect"
    if http.response_header.status == 200
      puts "Exitoso"
      EM.stop
    elsif http.response_header.status == 301
      http.redirects_count ? http.redirects_count += 1 : http.redirects_count = 1
      puts "***** redirects: #{http.redirects_count}"
      puts http.response_header.location
      redirect = EM::HttpRequest.new(http.response_header.location).get
      redirect.callback(&_handle_redirect)
      redirect.errback do
        EM.stop
      end
    else
      puts "No se que paso: #{http.error} - #{http.response_header.status}"
      EM.stop
    end
  }
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

