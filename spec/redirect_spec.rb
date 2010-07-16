require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'webrick'

describe "RDaneel" do

  describe "when there is no robots.txt in the host of the uri" do

    before(:all) do
      start_server do |s|
        s.mount_proc( '/hello_world', lambda { |req, resp|
                      resp.status = 200
                      resp.body = "Hello World!" } )
        s.mount_proc( '/2nd_redirect', lambda { |req, resp|
                      resp.status = 301
                      resp['Location'] = "http://127.0.0.1:8080/hello_world" } )
        s.mount_proc('/1st_redirect', lambda { |req, resp|
                      resp.status = 301;
                      resp['Location'] = "http://127.0.0.1:8080/2nd_redirect" } )
      end
    end

    after(:all) do
      stop_server
    end

    it "should follow all the redirects" do
      EM.run {
        r = RDaneel.new("http://127.0.0.1:8080/1st_redirect")
        r.callback {
          puts "callback"
          puts r.http_client.response
          puts r.redirects.inspect
          EM.stop
        }
        r.errback {
          puts "errback"
          puts r.error
          EM.stop
        }

        r.get(:redirects => 3)
      }
    end
  end
end

