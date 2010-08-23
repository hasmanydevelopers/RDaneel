require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there is a cache" do

  after(:each) do
    $server.reset
    RDaneel.robots_cache = nil # not sure if we should be reloading RDaneel instead
  end

  describe "when the port has not been specified" do
    it "should fetch the robots.txt just once"
  end

  describe "when there is no robots.txt in the host and url is redirected" do

    before(:each) do
      RDaneel.robots_cache = {}
      $server.mount(:path  => '/robots.txt',  :status => 404)
      $server.mount(:path  => '/redirect_me', :status => 301,
                    :location  => "http://127.0.0.1:3210/hello_world")
      $server.mount(:path  => '/hello_world', :status => 200,
                    :body  => 'Hello World!')
    end

    it "should fetch the robots.txt just once" do
      EM.run do
        r = RDaneel.new("http://127.0.0.1:3210/redirect_me")
        r.callback do
          r.http_client.response_header.status.should == 200
          r.http_client.response.should == "Hello World!"
          r.redirects.should == [ "http://127.0.0.1:3210/redirect_me"]
          r.uri.to_s.should == "http://127.0.0.1:3210/hello_world"

          requests = $server.requests
          
          requests.size.should == 3
          requests[0].should == {:status => 404, :path => "/robots.txt"}
          requests[1].should == {:status => 301, :path => "/redirect_me"}
          requests[2].should == {:status => 200, :path => "/hello_world"}
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

