require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there is a cache" do

  let(:port) {8080}

  describe "when there is no robots.txt in the host and url is redirected" do

    before(:each) do
      RDaneel.robots_cache = {}
      @server = Burrito.new(port)
      @server.mount(:path  => '/robots.txt',  :status => 404)
      @server.mount(:path  => '/redirect_me', :status => 301,
                    :location  => "http://127.0.0.1:#{port}/hello_world")
      @server.mount(:path  => '/hello_world', :status => 200,
                    :body  => 'Hello World!')
      @server.start
    end

    after(:each) do
      @server.shutdown
    end

    it "should try to get the robots.txt just once" do
      EM.run do
        r = RDaneel.new("http://127.0.0.1:#{port}/redirect_me")
        r.callback do
          r.http_client.response_header.status.should == 200
          r.http_client.response.should == "Hello World!"
          r.redirects.should == [ "http://127.0.0.1:#{port}/redirect_me"]
          r.uri.to_s.should == "http://127.0.0.1:#{port}/hello_world"
puts "***********"
puts @server.requests.inspect
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

