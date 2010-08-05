require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'logger'

describe "RDaneel" do

  describe "when there is not logger option set" do

    before(:each) do
      RDaneel.robots_cache = {}
      burrito.mount( :path  => '/robots.txt',  :status => 404 )
      burrito.mount( :path  => '/redirect_me', :status => 301,
                     :location  => 'http://127.0.0.1:8080/hello_world' )
      burrito.mount( :path  => '/hello_world', :status => 200,
                     :body  => 'Hello World!' )
    end

    after(:each) do
      burrito.unmount('/robots.txt')
      burrito.unmount('/redirect_me')
      burrito.unmount('/hello_world')
    end

    it "should not log anything to standard error" do
      $stderr = StringIO.new
      EM.run do
        r = RDaneel.new("http://127.0.0.1:8080/redirect_me")
        r.callback do
          r.http_client.response_header.status.should == 200
          r.http_client.response.should == "Hello World!"
          r.redirects.should == [ "http://127.0.0.1:8080/redirect_me"]
          r.uri.to_s.should == "http://127.0.0.1:8080/hello_world"
          EM.stop
        end
        r.errback do
          fail
          EM.stop
        end
        r.get(:redirects => 3)
        $stderr.read.should be_empty
      end
    end

  end

  describe "when there is a logger option set" do

    before(:each) do
      RDaneel.robots_cache = {}
      burrito.mount( :path  => '/robots.txt',  :status => 404 )
      burrito.mount( :path  => '/redirect_me', :status => 301,
                     :location  => 'http://127.0.0.1:8080/hello_world' )
      burrito.mount( :path  => '/hello_world', :status => 200,
                     :body  => 'Hello World!' )
    end

    after(:each) do
      burrito.unmount('/robots.txt')
      burrito.unmount('/redirect_me')
      burrito.unmount('/hello_world')
    end

    it "should log to standard error" do
      sio = StringIO.new
      siolog = Logger.new(sio)
      siolog.level = Logger::INFO
      EM.run do
        r = RDaneel.new("http://127.0.0.1:8080/redirect_me", :logger => siolog)
        r.callback do
          r.http_client.response_header.status.should == 200
          r.http_client.response.should == "Hello World!"
          r.redirects.should == [ "http://127.0.0.1:8080/redirect_me"]
          r.uri.to_s.should == "http://127.0.0.1:8080/hello_world"
          EM.stop
        end
        r.errback do
          fail
          EM.stop
        end
        r.get(:redirects => 3)
        sio.rewind
        sio.read.should_not be_empty
        sio.rewind
        sio.each_line { |l| puts l }
      end
    end

  end

end

