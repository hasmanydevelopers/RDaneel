require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are no redirects" do

  before(:all) do
    unless $server
      $server = Burrito.new
      $server.start  
    end
  end

  describe "when a successfull status different than 200 is issued for robots.txt" do
    it "should get the content ignoring the redirect"
  end

  describe "when a redirect other than 301 and 302 is issued for robots.txt" do
    it "should get the content ignoring the redirect"
  end

  (301..302).each do |status|

    describe "when robots.txt has been moved (http code #{status})" do
    
      before(:each) do
        $server.mount(:path  => '/hello_world', :status => 200,
                      :body  => 'Hello World!')
        $server.mount(:path  => '/robots.txt',  :status => status,
                      :location => "http://127.0.0.1:3210/golems.txt")
        $server.mount(:path  => '/golems.txt',  :status => 200)
      end

      after(:each) do
        $server.reset
      end

      it "should get the redirected robots.txt and the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:3210/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty

            requests = $server.requests

            requests.size.should == 3
            requests[0].should == { :status => status, :path => "/robots.txt"  }
            requests[1].should == { :status => 200,    :path => "/golems.txt"  }
            requests[2].should == { :status => 200,    :path => "/hello_world" }

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

