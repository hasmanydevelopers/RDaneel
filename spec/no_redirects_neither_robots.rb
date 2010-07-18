require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are no redirects" do

  before(:all) do
    @burrito = Burrito.new
  end

  after(:all) do
    @burrito.stop
  end

  (301..302).each do |status|

    describe "when robots.txt has been moved (#{status})" do

      it "should get the content ignoring the redirect" do

        EM.run do
          @burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!', :block  => should_be_hit_once )
          @burrito.mount( :path  => '/robots.txt',  :status => status,
                          :location => 'http://127.0.0.1:8080/golems.txt',
                          :block => should_be_hit_once )
          @burrito.mount( :path  => '/golems.txt',  :status => 200,
                          :block => should_not_be_hit )
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

      it "should get the content" do

        EM.run do
          @burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!', :block  => should_be_hit_once )
          @burrito.mount( :path  => '/robots.txt',  :status => status,
                          :block => should_be_hit_once )
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

      it "should get the content" do

        EM.run do
          @burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!', :block  => should_be_hit_once )
          @burrito.mount( :path  => '/robots.txt',  :status => status,
                          :block => should_be_hit_once )
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

