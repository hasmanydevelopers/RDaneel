require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel" do

  describe "when there are no redirects" do

    before(:all) do
      @burrito = Burrito.new
    end

    after(:all) do
      @burrito.stop
    end

    describe "when there is no robots.txt file" do

      before(:all) do
        @burrito.mount( '/hello_world', 200, 'Hello World!' )
      end

      it "should get the content withoud following any redirect" do

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

