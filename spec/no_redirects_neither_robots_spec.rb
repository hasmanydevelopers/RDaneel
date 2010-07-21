require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are no redirects" do

  describe "when not exist a robots.txt (404) and the url requested is /" do
    before(:each) do
      burrito.mount( :path  => '/', :status => 200,
                        :body  => 'Hello World!', :block  => should_be_hit_once )
      burrito.mount( :path  => '/robots.txt',  :status => 404,
                        :block => should_be_hit_once )
    end

    after(:each) do
      burrito.unmount('/')
      burrito.unmount('/robots.txt')
    end

    it "should get the content is the url not end with /" do

      EM.run do
        r = RDaneel.new("http://127.0.0.1:8080")
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



  describe "when a successfull status different than 200 is issued for robots.txt" do

    it "should get the content ignoring the redirect"

  end

  describe "when a redirect other than 301 and 302 is issued for robots.txt" do

    it "should get the content ignoring the redirect"

  end

  (301..302).each do |status|

    describe "when robots.txt has been moved (http code #{status})" do
      before(:each) do
        burrito.mount( :path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!', :block  => should_be_hit_once )
        burrito.mount( :path  => '/robots.txt',  :status => status,
                        :location => 'http://127.0.0.1:8080/golems.txt',
                        :block => should_be_hit_once )
        burrito.mount( :path  => '/golems.txt',  :status => 200,
                        :block => should_not_be_hit )
      end

      after(:each) do
        burrito.unmount('/hello_world')
        burrito.unmount('/robots.txt')
        burrito.unmount('/golems.txt')
      end

      it "should get the content ignoring the redirect" do

        EM.run do
          r = RDaneel.new("http://127.0.0.1:8080/hello_world")
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
        burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!', :block  => should_be_hit_once )
        burrito.mount( :path  => '/robots.txt',  :status => status,
                          :block => should_be_hit_once )
      end

      after(:each) do
        burrito.unmount('/hello_world')
        burrito.unmount('/robots.txt')
      end

      it "should get the content" do

        EM.run do
          r = RDaneel.new("http://127.0.0.1:8080/hello_world")
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
        burrito.mount( :path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!', :block  => should_be_hit_once )
        burrito.mount( :path  => '/robots.txt',  :status => status,
                        :block => should_be_hit_once )
      end

      after (:each) do
        burrito.unmount('/hello_world')
        burrito.unmount('/robots.txt')
      end

      it "should get the content" do

        EM.run do
          r = RDaneel.new("http://127.0.0.1:8080/hello_world")
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

