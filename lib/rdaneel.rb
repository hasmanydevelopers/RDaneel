require 'em-http'
require 'robot_rules'

class RDaneel
  include EM::Deferrable

  DEFAULT_OPTIONS = {:head => {'user-agent' => 'RDaneel'}}

  class << self
    def robots_cache=(c)
      @robots_cache = c
    end

    def robots_cache
      @robots_cache
    end
  end

  attr_accessor :uri
  attr_reader :error, :redirects, :http_client

  def initialize(uri,options = {})
    @uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri)
    @uri.path = "/" if @uri.path.nil? || @uri.path == ""
    @redirects = []
    @logger = options[:logger]
    unless @logger
      require 'logger'
      @logger = Logger.new($stderr)
      @logger.level = Logger::ERROR
    end
  end

  def get(opts = {})
    @logger.info("Starting fetching: #{@uri}")
    current_uri = @uri
    options = DEFAULT_OPTIONS.merge(opts)
    max_redirects = options.delete(:redirects).to_i
    useragent = options[:head]['user-agent']

    _get = lambda {}

    _handle_uri_callback = lambda {|h|
      if success?(h)
        @uri = current_uri if current_uri != @uri
        @http_client = h
        @logger.info("Succeded fetching: #{current_uri} (#{@uri})")
        succeed(self)
      elsif redirected?(h)
        if @redirects.size >= max_redirects
          @http_client = h
          @error = "Exceeded maximum number of redirects (#{max_redirects})"
          @logger.error(@error)
          fail(self)
          return
        end
        begin
          @logger.info("Redirected to: #{current_uri.to_s}")
          @redirects << current_uri.to_s
          current_uri = redirect_url(h, current_uri)
          if @redirects.include?(current_uri.to_s)
            @http_client = h
            @error = "infinite redirect"
            @logger.error(@error)
            fail(self)
            return
          end
          _get.call
        rescue
          @http_client = h
          @error = "mal formed redirected url"
          @logger.error(@error)
          fail(self)
        end
      else
        # other error
        @http_client = h
        @error = "not success and not redirect"
        @logger.error(@error)
        fail(self)
      end
    }
    _get = lambda {
      robots_url = robots_txt_url(current_uri)
      @logger.info("Robots URL: #{robots_url}")
      if robots_cache && robots_file = robots_cache[robots_url.to_s]
        @logger.info('robots.txt is cached')
        if robots_allowed?(robots_file, useragent, robots_url, current_uri)
          @logger.info('Robots are allowed')
          begin
            @logger.info("Starting fetching: #{current_uri}")
            h = EM::HttpRequest.new(current_uri).get(options)
            h.callback(&_handle_uri_callback)
            h.errback {
              @http_client = h
              @error = h.error
              @logger.error(@error)
              fail(self)
            }
          rescue StandardError => se
            @http_client = EM::HttpClient.new("")
            @error = "#{se.message}\n#{se.backtrace.inspect}"
            @logger.error(@error)
            fail(self)
          end
        else
          @http_client = EM::HttpClient.new("")
          @error = "robots denied"
          @logger.error(@error)
          fail(self)
        end
      else
        robots_url = robots_txt_url(current_uri)
        @logger.info("Starting fetching robots.txt at: #{robots_url}")
        robots = EM::HttpRequest.new(robots_url).get
        robots.callback {
          @logger.info("Found robots.txt at: #{current_uri}")
          robots_file = robots.response
          @logger.info(robots_file)
          robots_cache[robots_url.to_s] = robots_file if robots_cache
          if robots_allowed?(robots_file, useragent, robots_url, current_uri)
            @logger.info('Robots are allowed')
            begin
              @logger.info("Starting fetching: #{current_uri}")
              h = EM::HttpRequest.new(current_uri).get(options)
              h.callback(&_handle_uri_callback)
              h.errback {
                @http_client = h
                @error = h.error
                @logger.error(@error)
                fail(self)
              }
            rescue StandardError => se
              @http_client = EM::HttpClient.new("")
              @error = "#{se.message}\n#{se.backtrace.inspect}"
              @logger.error(@error)
              fail(self)
            end
          else
            @http_client = EM::HttpClient.new("")
            @error = "robots denied"
            @logger.error(@error)
            fail(self)
          end
        }
        robots.errback {
          robots_cache[robots_url.to_s] = "" if robots_cache
          @logger.info("Starting fetching: #{current_uri}")
          h = EM::HttpRequest.new(current_uri).get(options)
          h.callback(&_handle_uri_callback)
          h.errback {
            @http_client = h
            @error = h.error
            @logger.error(@error)
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

  def robots_allowed?(robots_file, useragent, robots_url, url)
    begin
      rules = RobotRules.new(useragent)
      rules.parse(robots_url, robots_file)
      return rules.allowed? url
    rescue StandardError => err
      return true
    end
  end

  def robots_txt_url(u)
    location = if u.port == 80
      u.host
    else
      "#{u.host}:#{u.port}"
    end
    Addressable::URI.parse("http://#{location}/robots.txt")
  end

  def success?(http_client)
    http_client.response_header.status == 200
  end

  def redirected?(http_client)
    http_client.response_header.status == 301 || http_client.response_header.status == 302
  end

  def redirect_url(http_client, u)
    location = Addressable::URI.parse(http_client.response_header.location)
    location = u.join(location) if location.relative?
    location.path = "/" if location.path.nil? || location.path == ""
    location
  end

end

