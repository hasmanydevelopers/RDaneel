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

  attr_accessor :uri
  attr_reader :error, :redirects, :http_client

  def initialize(uri)
    @uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri)
    @redirects = []
  end

  def get(opts = {})
    current_uri = @uri
    options = DEFAULT_OPTIONS.merge(opts)
    max_redirects = options.delete(:redirects).to_i
    useragent = options[:head]['user-agent']

    _get = lambda {}

    _handle_uri_callback = lambda {|h|
      if success?(h)
        @uri = current_uri if current_uri != @uri
        @http_client = h
        succeed(self)
      elsif redirected?(h)
        if @redirects.size >= max_redirects
          @http_client = h
          @error = "excedded max redirects"
          fail(self)
          return
        end
        begin
          @redirects << current_uri.to_s
          current_uri = redirect_url(h, current_uri)
          if @redirects.include?(current_uri.to_s)
            @http_client = h
            @error = "infinite redirect"
            fail(self)
            return
          end
          _get.call
        rescue
          @http_client = h
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
      if robots_cache && robots_file = robots_cache.get(robots_txt_url(current_uri))
        if robots_allowed?(robots_file, useragent, current_uri)
          h = EM::HttpRequest.new(current_uri).get(options)
          h.callback(&_handle_uri_callback)
          h.errback {
            @http_client = h
            @error = h.error
            fail(self)
          }
        else
          @http_client = EM::HttpClient.new("")
          @error = "robots denied"
          fail(self)
        end
      else
        robots = EM::HttpRequest.new(robots_txt_url(current_uri)).get
        robots.callback {
          robots_file = robots.response
          robots_cache.put(robots_txt_url(current_uri), robots_file) if robots_cache
          if robots_allowed?(robots_file, useragent, current_uri)
            h = EM::HttpRequest.new(current_uri).get(options)
            h.callback(&_handle_uri_callback)
            h.errback {
              @http_client = h
              @error = h.error
              fail(self)
            }
          else
            @http_client = EM::HttpClient.new("")
            @error = "robots denied"
            fail(self)
          end
        }
        robots.errback {
          robots_cache.put(robots_txt_url(current_uri), "") if robots_cache
          h = EM::HttpRequest.new(current_uri).get(options)
          h.callback(&_handle_uri_callback)
          h.errback {
            @http_client = h
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

  def robots_allowed?(robots_file, useragent, u)
    rules = RobotRules.new(useragent)
    rules.parse(u.to_s, robots_file)
    rules.allowed? u.to_s
  end

  def robots_txt_url(u)
    location = if u.port == 80
      u.host
    else
      "#{u.host}:#{u.port}"
    end
    "http://#{location}/robots.txt"
  end

  def success?(http_client)
    http_client.response_header.status == 200
  end

  def redirected?(http_client)
    http_client.response_header.status == 301 || http_client.response_header.status == 302
  end

  def redirect_url(http_client, u)
    location = Addressable::URI.parse(http_client.response_header.location)
    return u.join(location) if location.relative?
    return location
  end
end

