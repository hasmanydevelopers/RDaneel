require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are redirects" do

  describe "when there is no robots.txt in the host (ONLY one host)" do

    before(:each) do
      @burrito = Burrito.new
    end

    after(:each) do
      @burrito.stop
    end

    describe "when no redirection limit has been set" do

      it "should not follow redirects" do

        @burrito.mount( :path  => '/robots.txt',  :status => 404,
                        :block => should_be_hit_once )
        @burrito.mount( :path  => '/redirect_me', :status => 301,
                        :location  => 'http://127.0.0.1:8080/hello_world',
                        :block  => should_be_hit_once )
        @burrito.mount( :path  => '/hello_world', :status => 200,
                        :body  => 'Hello World!',
                        :block  => should_not_be_hit )

        EM.run do
          r = RDaneel.new("http://127.0.0.1:8080/redirect_me")
          r.callback do
            fail
            EM.stop
          end
          r.errback do
            r.redirects.should be_empty
            r.error.should == "Exceeded maximum number of redirects"
            EM.stop
          end
          r.get
        end

      end

    end

    describe "when a maximum number or redirects is set" do

      describe "when there are less redirects than the maximum specified" do

        it "should get the content following all the redirects" do

          @burrito.mount( :path  => '/robots.txt',  :status => 404,
                          :block => should_be_hit(3) )
          @burrito.mount( :path  => '/redirect_me', :status => 301,
                          :location  => 'http://127.0.0.1:8080/redirect_me_again',
                          :block  => should_be_hit_once )
          @burrito.mount( :path  => '/redirect_me_again', :status => 301,
                          :location  => 'http://127.0.0.1:8080/hello_world',
                          :block  => should_be_hit_once )
          @burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!',
                          :block  => should_be_hit_once )
          EM.run do
            r = RDaneel.new("http://127.0.0.1:8080/redirect_me")
            r.callback do
              r.http_client.response_header.status.should == 200
              r.http_client.response.should == "Hello World!"
              r.redirects.should == [ "http://127.0.0.1:8080/redirect_me",
                                      "http://127.0.0.1:8080/redirect_me_again"]
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

      describe "when there are as many redirects as the maximum" do

        it "should get the content following all the redirects" do

          @burrito.mount( :path  => '/robots.txt',  :status => 404,
                          :block => should_be_hit_twice )
          @burrito.mount( :path  => '/redirect_me', :status => 301,
                          :location  => 'http://127.0.0.1:8080/hello_world',
                          :block  => should_be_hit_once )
          @burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!',
                          :block  => should_be_hit_once )
          EM.run do
            r = RDaneel.new("http://127.0.0.1:8080/redirect_me")
            r.callback do
              r.http_client.response_header.status.should == 200
              r.http_client.response.should == "Hello World!"
              r.redirects.should == ['http://127.0.0.1:8080/redirect_me']
              r.uri.to_s.should == "http://127.0.0.1:8080/hello_world"
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

        it "should stop following redirects once the  maximum specified is reached" do

          @burrito.mount( :path  => '/robots.txt',  :status => 404,
                          :block => should_be_hit_twice )
          @burrito.mount( :path  => '/redirect_me', :status => 301,
                          :location  => 'http://127.0.0.1:8080/redirect_me_again',
                          :block  => should_be_hit_once )
          @burrito.mount( :path  => '/redirect_me_again', :status => 301,
                          :location  => 'http://127.0.0.1:8080/hello_world',
                          :block  => should_be_hit_once )
          @burrito.mount( :path  => '/hello_world', :status => 200,
                          :body  => 'Hello World!',
                          :block  => should_not_be_hit )

          EM.run do
            r = RDaneel.new("http://127.0.0.1:8080/redirect_me")
            r.callback do
              fail
              EM.stop
            end
            r.errback do
              r.redirects.should == ['http://127.0.0.1:8080/redirect_me']
              r.error.should == "Exceeded maximum number of redirects"
              EM.stop
            end
            r.get(:redirects => 1)
          end

        end

      end

    end

  end

end

