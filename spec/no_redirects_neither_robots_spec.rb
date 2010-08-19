require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are no redirects" do

  let(:port) {8080}

  describe "when a successfull status different than 200 is issued for robots.txt" do
    it "should get the content ignoring the redirect"
  end

  describe "when a redirect other than 301 and 302 is issued for robots.txt" do
    it "should get the content ignoring the redirect"
  end

  (301..302).each do |status|

    describe "when robots.txt has been moved (http code #{status})" do
      before(:each) do
        @server = Burrito.new(port)
        @server.mount(:path  => '/hello_world', :status => 200,
                      :body  => 'Hello World!')
        @server.mount(:path  => '/robots.txt',  :status => status,
                      :location => "http://127.0.0.1:#{port}/golems.txt")
        @server.mount(:path  => '/golems.txt',  :status => 200)
        @server.start
      end

      after(:each) do
        @server.shutdown
      end

      it "should get the redirected robots.txt and the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port}/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty

            served_requests = @server.served_requests
            served_requests.size.should == 3
            served_requests[0].should == {:status => status, :url => "/robots.txt"}
            served_requests[1].should == {:status => 200, :url => "/golems.txt"}
            served_requests[2].should == {:status => 200, :url => "/hello_world"}

            EM.stop
          end
          r.errback do
            fail
            EM.stop
          end
          r.get
        end
      end

    end

  end

  (400..417).each do |status|

    describe "when there is a CLIENT error #{status} associated to robots.txt" do
      before(:each) do
        @server = Burrito.new(port+status)
        @server.mount(:path  => '/hello_world', :status => 200,
                      :body  => 'Hello World!')
        @server.mount(:path  => '/robots.txt',  :status => status)
        @server.start
      end

      after(:each) do
        @server.shutdown
      end

      it "should get the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port+status}/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty

            served_requests = @server.served_requests
            served_requests.size.should == 2
            served_requests[0].should == {:status => status, :url => "/robots.txt"}
            served_requests[1].should == {:status => 200, :url => "/hello_world"}
            EM.stop
          end
          r.errback do
            fail
            EM.stop
          end
          r.get
        end
      end

    end

  end

  (500..505).each do |status|

    describe "when there is a SERVER error #{status} associated to robots.txt" do
      before(:each) do
        @server = Burrito.new(port+status)
        @server.mount(:path  => '/hello_world', :status => 200,
                      :body  => 'Hello World!')
        @server.mount(:path  => '/robots.txt',  :status => status)
        @server.start
      end

      after (:each) do
        @server.shutdown
      end

      it "should get the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port+status}/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty

            served_requests = @server.served_requests
            served_requests.size.should == 2
            served_requests[0].should == {:status => status, :url => "/robots.txt"}
            served_requests[1].should == {:status => 200, :url => "/hello_world"}

            EM.stop
          end
          r.errback do
            fail
            EM.stop
          end
          r.get
        end
      end

    end

  end

end

