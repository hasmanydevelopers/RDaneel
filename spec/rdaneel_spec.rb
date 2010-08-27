require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDaneel" do

  describe "robots_txt_url" do
    before(:each) do
      @rdaneel = RDaneel.new("http://127.0.0.1/anyurl")
    end

    it "should return the proper url when url don't has a port specified (80 implied)" do
      url = Addressable::URI.parse("http://127.0.0.1/path/url?param1=value1&param2=value2")
      @rdaneel.send(:robots_txt_url,url).to_s.should == "http://127.0.0.1/robots.txt"
    end

    it "should return the proper url when url has a port 80 specified" do
      url = Addressable::URI.parse("http://127.0.0.1:80/path/url?param1=value1&param2=value2")
      @rdaneel.send(:robots_txt_url,url).to_s.should == "http://127.0.0.1/robots.txt"
    end

    it "should return the proper url when url has a port different than 80" do
      url = Addressable::URI.parse("http://127.0.0.1:8080/path/url?param1=value1&param2=value2")
      @rdaneel.send(:robots_txt_url,url).to_s.should == "http://127.0.0.1:8080/robots.txt"
    end

  end
end

