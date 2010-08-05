require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'logger'

describe "RDaneel" do

  describe "when there is a logger option set" do

    before(:each) do
      RDaneel.robots_cache = {}
      burrito.mount( :path  => '/robots.txt', :status => 200,
                     :body  => "User-agent: *\nDisallow: /private" )
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

      EM.run do
        r = RDaneel.new("http://127.0.0.1:8080/redirect_me", :verbose => true)
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
      end
    end

  end

end

