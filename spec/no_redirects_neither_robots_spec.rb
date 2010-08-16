require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are no redirects" do

  let(:port) {8083}

  describe "when a successfull status different than 200 is issued for robots.txt" do
    it "should get the content ignoring the redirect"
  end

  describe "when a redirect other than 301 and 302 is issued for robots.txt" do
    it "should get the content ignoring the redirect"
  end

  (301..302).each do |status|

    describe "when robots.txt has been moved (http code #{status})" do
      before(:each) do
        server_setup(port+status) do |server|
          mount(server, :path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!', :block  => should_be_hit_once )
          mount(server, :path  => '/robots.txt',  :status => status,
                        :location => "http://127.0.0.1:#{port+status}/golems.txt",
                        :block => should_be_hit_once )
          mount(server, :path  => '/golems.txt',  :status => 200,
                        :block => should_be_hit_once )
        end
      end

      after(:each) do
        server_shutdown
      end

      it "should get the redirected robots.txt and the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port+status}/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty
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
        server_setup(port+status) do |server|
          mount(server, :path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!', :block  => should_be_hit_once )
          mount(server, :path  => '/robots.txt',  :status => status,
                        :block => should_be_hit_once )
        end
      end

      after(:each) do
        server_shutdown
      end

      it "should get the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port+status}/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty
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
        server_setup(port+status) do |server|
          mount(server, :path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!', :block  => should_be_hit_once )
          mount(server, :path  => '/robots.txt',  :status => status,
                        :block => should_be_hit_once )
        end
      end

      after (:each) do
        server_shutdown
      end

      it "should get the content" do
        EM.run do
          r = RDaneel.new("http://127.0.0.1:#{port+status}/hello_world")
          r.callback do
            r.http_client.response_header.status.should == 200
            r.http_client.response.should == "Hello World!"
            r.redirects.should be_empty
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

