require 'em-http'
require 'robot_rules'

class RDaneel
  include EM::Deferrable

  DEFAULT_OPTIONS = {:head => {'user-agent' => 'RDaneel'}}

  class << self
    def robots_cache=(klass, options={})
      @robots_cache = klass.new(options)
    end

    def robots_cache
      @robots_cache
    end
  end

  attr_accessor :uri, :redirects, :http_client
  attr_reader :error

  def initialize(uri)
    self.uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri)
    self.redirects = []
  end

  def get(options = {})
    max_redirects = options.delete(:redirects).to_i
    options = DEFAULT_OPTIONS.merge(options)
    useragent = options[:head]['user-agent']

    _get = lambda {}

    _handle_uri_callback = lambda {|h|
      if success?(h)
        self.http_client = h
        succeed(self)
      elsif redirected?(h)
        begin
          self.uri = redirect_url(h)
          self.redirects << self.uri.to_s
          _get.call
        rescue
          self.http_client = h
          @error = "mal formed redirected url"
          fail(self)
        end
      else
        # other error
        self.http_client = h
        @error = "not success and not redirect"
        fail(self)
      end
    }
    _get = lambda {
      if robots_cache && robots_file = robots_cache.get(robots_txt_url)
        if robots_allowed?(robots_file, useragent)
          h = EM::HttpRequest.new(self.uri).get(options)
          h.callback(&_handle_uri_callback)
          h.errback {
            self.http_client = h
            @error = h.error
            fail(self)
          }
        else
          self.http_client = EM::HttpClient.new("")
          @error = "robots denied"
          fail(self)
        end
      else
        robots = EM::HttpRequest.new(robots_txt_url).get
        robots.callback {
          robots_file = robots.response
          robots_cache.put(robots_txt_url, robots_file) if robots_cache
          if robots_allowed?(robots_file, useragent)
            h = EM::HttpRequest.new(@uri).get(options)
            h.callback(&_handle_uri_callback)
            h.errback {
              self.http_client = h
              @error = h.error
              fail(self)
            }
          else
            self.http_client = EM::HttpClient.new("")
            @error = "robots denied"
            fail(self)
          end
        }
        robots.errback {
          robots_cache.put(robots_txt_url, "") if robots_cache
          h = EM::HttpRequest.new(@uri).get(options)
          h.callback(&_handle_uri_callback)
          h.errback {
            self.http_client = h
            @error = h.error
            fail(self)
          }
        }
      end
    }
    _get.call
  end

  def robots_cache
    self.class.robots_cache
  end

  protected

  def robots_allowed?(robots_file, useragent)
    rules = RobotRules.new(useragent)
    rules.parse(@uri.to_s, robots_file)
    rules.allowed? @uri.to_s
  end

  def robots_txt_url
    location = if self.uri.port == 80
      self.uri.host
    else
      "#{self.uri.host}:#{self.uri.port}"
    end
    "http://#{location}/robots.txt"
  end

  def success?(http_client)
    http_client.response_header.status == 200
  end

  def redirected?(http_client)
    http_client.response_header.status == 301 || http_client.response_header.status == 302
  end

  def redirect_url(http_client)
    location = Addressable::URI.parse(http_client.response_header.location)
    return self.uri.join(location) if location.relative?
    return location
  end
end

