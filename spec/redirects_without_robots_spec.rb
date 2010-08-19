require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are redirects" do

  let(:port) {8081}

  describe "when there is no robots.txt in the host (ONLY one host)" do

    describe "when no redirection limit has been set" do
      before(:each) do
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

      it "should not follow redirects" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port}/redirect_me")
          r.callback do
            fail
            EM.stop
          end
          r.errback do
            r.redirects.should be_empty
            r.error.should == "Exceeded maximum number of redirects: 0"

            served_requests = @server.served_requests
            served_requests.size.should == 2
            served_requests[0].should == {:status => 404, :url => "/robots.txt"}
            served_requests[1].should == {:status => 301, :url => "/redirect_me"}

            EM.stop
          end
          r.get
        end

      end

    end

    describe "when a maximum number or redirects is set" do

      describe "when there are less redirects than the maximum specified" do
        before(:each) do
          @server = Burrito.new(port)
          @server.mount(:path  => '/robots.txt',  :status => 404)
          @server.mount(:path  => '/redirect_me', :status => 301,
                        :location  => "http://127.0.0.1:#{port}/redirect_me_again")
          @server.mount(:path  => '/redirect_me_again', :status => 301,
                        :location  => "http://127.0.0.1:#{port}/hello_world")
          @server.mount(:path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!')
          @server.start
        end

        after(:each) do
          @server.shutdown
        end

        it "should get the content following all the redirects" do
          EM.run do
            r = RDaneel.new("http://127.0.0.1:#{port}/redirect_me")
            r.callback do
              r.http_client.response_header.status.should == 200
              r.http_client.response.should == "Hello World!"
              r.redirects.should == [ "http://127.0.0.1:#{port}/redirect_me",
                                      "http://127.0.0.1:#{port}/redirect_me_again"]
              r.uri.to_s.should == "http://127.0.0.1:#{port}/hello_world"

              served_requests = @server.served_requests
              served_requests.size.should == 6
              served_requests[0].should == {:status => 404, :url => "/robots.txt"}
              served_requests[1].should == {:status => 301, :url => "/redirect_me"}
              served_requests[2].should == {:status => 404, :url => "/robots.txt"}
              served_requests[3].should == {:status => 301, :url => "/redirect_me_again"}
              served_requests[4].should == {:status => 404, :url => "/robots.txt"}
              served_requests[5].should == {:status => 200, :url => "/hello_world"}

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

      describe "when there are as many redirects as the maximum" do
        before(:each) do
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

        it "should get the content following all the redirects" do
          EM.run do
            r = RDaneel.new("http://127.0.0.1:#{port}/redirect_me")
            r.callback do
              r.http_client.response_header.status.should == 200
              r.http_client.response.should == "Hello World!"
              r.redirects.should == ["http://127.0.0.1:#{port}/redirect_me"]
              r.uri.to_s.should == "http://127.0.0.1:#{port}/hello_world"

              served_requests = @server.served_requests
              served_requests.size.should == 4
              served_requests[0].should == {:status => 404, :url => "/robots.txt"}
              served_requests[1].should == {:status => 301, :url => "/redirect_me"}
              served_requests[2].should == {:status => 404, :url => "/robots.txt"}
              served_requests[3].should == {:status => 200, :url => "/hello_world"}
              EM.stop
            end
            r.errback do
              fail
              EM.stop
            end
            r.get(:redirects => 1)
          end

        end

      end

      describe "when the number of redirects exceed the maximum specified" do
        before(:each) do
          @server = Burrito.new(port)
          @server.mount(:path  => '/robots.txt',  :status => 404)
          @server.mount(:path  => '/redirect_me', :status => 301,
                        :location  => "http://127.0.0.1:#{port}/redirect_me_again")
          @server.mount(:path  => '/redirect_me_again', :status => 301,
                        :location  => "http://127.0.0.1:#{port}/hello_world")
          @server.mount(:path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!')
          @server.start
        end

        after(:each) do
          @server.shutdown
        end

        it "should stop following redirects once the  maximum specified is reached" do
          EM.run do
            r = RDaneel.new("http://127.0.0.1:#{port}/redirect_me")
            r.callback do
              fail
              EM.stop
            end
            r.errback do
              r.redirects.should == ["http://127.0.0.1:#{port}/redirect_me"]
              r.error.should == "Exceeded maximum number of redirects: 1"

              served_requests = @server.served_requests
              served_requests.size.should == 4
              served_requests[0].should == {:status => 404, :url => "/robots.txt"}
              served_requests[1].should == {:status => 301, :url => "/redirect_me"}
              served_requests[2].should == {:status => 404, :url => "/robots.txt"}
              served_requests[3].should == {:status => 301, :url => "/redirect_me_again"}
              EM.stop
            end
            r.get(:redirects => 1)
          end

        end

      end

    end

  end

end

