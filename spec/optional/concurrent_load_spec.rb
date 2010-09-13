require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "RDaneel when access a lot of urls in parallel for twitlonger.com" do

  before(:each) do
    @user_agent = 'Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Ubuntu/10.04 Chromium/7.0.513.0 Chrome/7.0.513.0 Safari/534.7'
    @http_accept = 'application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8'
  end

  after(:each) do
    RDaneel.robots_cache = nil
  end

  describe "and urls are not redirected" do

    before(:each) do
      @urls_file = File.expand_path(File.dirname(__FILE__) + '/fixtures/twitlonger_com_urls.txt')
    end

    it "should get the content for each url" do
      RDaneel.robots_cache = {}
      RDaneel.robots_cache["http://www.twitlonger.com/robots.txt"] = ""
      successes = 0
      failures = 0
      urls_in_queue = 0
      total_urls = 0
      EM.run do
        File.open(@urls_file).each do |url|
          unless url.nil? || url.strip.empty?
            r = RDaneel.new(url)
            r.callback do
              successes += 1
              urls_in_queue -= 1
              EM.stop if urls_in_queue == 0
            end
            r.errback do
              failures += 1
              urls_in_queue -= 1
              EM.stop if urls_in_queue == 0
            end
            r.get(:redirects => 10, :timeout => 20,
                  :head => {
                    'user-agent' => @user_agent,
                    'http_accept' => @http_accept
                  }
            )
            urls_in_queue += 1
            total_urls += 1
          end
        end
      end
      successes.should == total_urls
      failures.should == 0
    end

  end

  describe "and urls are redirected" do

    before(:each) do
      @urls_file = File.expand_path(File.dirname(__FILE__) + '/fixtures/tl_gd_urls.txt')
    end

    it "should get the content for each url" do
      RDaneel.robots_cache = {}
      RDaneel.robots_cache["http://www.twitlonger.com/robots.txt"] = ""
      RDaneel.robots_cache["http://tl.gd/robots.txt"] = ""
      successes = 0
      failures = 0
      urls_in_queue = 0
      total_urls = 0
      EM.run do
        File.open(@urls_file).each do |url|
          unless url.nil? || url.strip.empty?
            r = RDaneel.new(url)
            r.callback do
              successes += 1
              urls_in_queue -= 1
              EM.stop if urls_in_queue == 0
            end
            r.errback do
              failures += 1
              urls_in_queue -= 1
              EM.stop if urls_in_queue == 0
            end
            r.get(:redirects => 10, :timeout => 20,
                  :head => {
                    'user-agent' => @user_agent,
                    'http_accept' => @http_accept
                  }
            )
            urls_in_queue += 1
            total_urls += 1
          end
        end
      end
      successes.should == total_urls
      failures.should == 0
    end

  end

end

