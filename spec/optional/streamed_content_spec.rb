require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "RDaneel when the content is chunked (digg.com)" do

  # digg.com uses chunked encoding
  # http://www.digg.com is redirected to http://digg.com

  describe "when the url is not redirected" do

    it "should get the content" do
      EM.run do
        r = RDaneel.new("http://digg.com/news")
        r.callback do
          r.http_client.response_header.status.should == 200
          r.http_client.response.should_not be_empty
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

  describe "when the url is redirected" do
    it "should get the content" do
      EM.run do
        r = RDaneel.new("http://bit.ly:80/aquXKU")
        r.callback do
          r.http_client.response_header.status.should == 200
          r.http_client.response.should_not be_empty
          r.redirects.should == ['http://bit.ly:80/aquXKU']
          r.uri.to_s.should == "http://www.relevancesells.com:80/2010/03/12/the-1st-7-seconds-rule-for-an-elevator-pitch/"
          EM.stop
        end
        r.errback do
          puts "Error: #{r.error}"
          fail
          EM.stop
        end
        r.get(:redirects => 3)
      end
    end
  end

end

