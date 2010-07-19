require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel when there are redirects" do

  describe "when there is no robots.txt in the host (ONLY one host)" do

    before(:all) do
      @burrito = Burrito.new
    end

    after(:all) do
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


  end

end

