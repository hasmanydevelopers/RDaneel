require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'webrick'

describe "RDaneel" do

  describe "when there is no robots.txt" do
    before(:all) do
      start_server do |s|
        s.mount_proc('/hello_world', lambda { |req, resp| resp.status = 200; resp.body = "hello world"})
      end
    end

    after(:all) do
      stop_server
    end

    it "should follow and get the uri" do
      EM.run {
        RDaneel.new("http://127.0.0.1:8080/hello_world").get do |http|
          http.response_header.status.should == 200
          http.response.should == "hello world"
          http.error.should == ''
          EM.stop
        end
      }
    end
  end

  describe "when there is a robots.txt that allow the uri requested" do
    before(:all) do
      start_server do |s|
        s.mount_proc('/robots.txt', lambda { |req, resp| resp.status = 200; resp.body = "User-agent: *\nDisallow: /images"})
        s.mount_proc('/hello_world', lambda { |req, resp| resp.status = 200; resp.body = "hello world"})
      end
    end

    after(:all) do
      stop_server
    end

    it "should follow and get the uri" do
      EM.run {
        RDaneel.new("http://127.0.0.1:8080/hello_world").get do |http|
          http.response_header.status.should == 200
          http.response.should == "hello world"
          http.error.should == ''
          EM.stop
        end
      }
    end
  end

  describe "when there is a robots.txt that disallow all content for all bots" do
    before(:all) do
      start_server do |s|
        s.mount_proc('/robots.txt', lambda { |req, resp| resp.status = 200; resp.body = "User-agent: *\nDisallow: /"})
        s.mount_proc('/hello_world', lambda { |req, resp| resp.status = 200; resp.body = "hello world"})
      end
    end

    after(:all) do
      stop_server
    end

    it "shouldn't get the uri" do
      EM.run {
          RDaneel.new("http://127.0.0.1:8080/hello_world").get do |http|
          http.error.should == 'robots.txt'
          http.uri.to_s.should == "http://127.0.0.1:8080/hello_world"
          EM.stop
        end
      }
    end
  end



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

