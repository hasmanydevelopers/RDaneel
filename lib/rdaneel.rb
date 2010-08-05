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
    @verbose = options[:verbose]
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
        puts("Succeded fetching: #{current_uri} (#{@uri})") if @verbose
        succeed(self)
      elsif redirected?(h)
        if @redirects.size >= max_redirects
          @http_client = h
          @error = "Exceeded maximum number of redirects (#{max_redirects})"
          puts(@error) if @verbose
          fail(self)
          return
        end
        begin
          @redirects << current_uri.to_s
          current_uri = redirect_url(h, current_uri)
          puts("Redirected to: #{current_uri.to_s} from #{@redirects[-1]}") if @verbose
          if @redirects.include?(current_uri.to_s)
            @http_client = h
            @error = "infinite redirect"
            puts(@error) if @verbose
            fail(self)
            return
          end
          _get.call
        rescue
          @http_client = h
          @error = "mal formed redirected url"
          puts(@error) if @verbose
          fail(self)
        end
      else
        # other error
        @http_client = h
        @error = "not success and not redirect"
        puts(@error) if @verbose
        fail(self)
      end
    }
    _get = lambda {
      robots_url = robots_txt_url(current_uri)
      if robots_cache && robots_file = robots_cache[robots_url.to_s]
        puts("Found cached robots.txt(#{robots_url.to_s}):\n#{robots_cache[robots_url.to_s]}") if @verbose
        if robots_allowed?(robots_file, useragent, robots_url, current_uri)
          puts("Robots are allowed to access #{current_uri}") if @verbose
          begin
            puts("Started fetching: #{current_uri}") if @verbose
            h = EM::HttpRequest.new(current_uri).get(options)
            h.callback(&_handle_uri_callback)
            h.errback {
              @http_client = h
              @error = h.error
              puts(@error) if @verbose
              fail(self)
            }
          rescue StandardError => se
            @http_client = EM::HttpClient.new("")
            @error = "#{se.message}\n#{se.backtrace.inspect}"
            puts(@error) if @verbose
            fail(self)
          end
        else
          @http_client = EM::HttpClient.new("")
          @error = "robots denied"
          puts(@error) if @verbose
          fail(self)
        end
      else
        robots_url = robots_txt_url(current_uri)
        puts("Started fetching robots.txt from: #{robots_url} for #{current_uri}") if @verbose
        robots = EM::HttpRequest.new(robots_url).get
        robots.callback {
          robots_file = robots.response
          puts("Found robots.txt at #{current_uri}:\n#{robots_file}") if @verbose
          robots_cache[robots_url.to_s] = robots_file if robots_cache
          if robots_allowed?(robots_file, useragent, robots_url, current_uri)
            puts("Robots are allowed to access #{current_uri}") if @verbose
            begin
              puts("Started fetching: #{current_uri}") if @verbose
              h = EM::HttpRequest.new(current_uri).get(options)
              h.callback(&_handle_uri_callback)
              h.errback {
                @http_client = h
                @error = h.error
                puts(@error) if @verbose
                fail(self)
              }
            rescue StandardError => se
              @http_client = EM::HttpClient.new("")
              @error = "#{se.message}\n#{se.backtrace.inspect}"
              puts(@error) if @verbose
              fail(self)
            end
          else
            @http_client = EM::HttpClient.new("")
            @error = "robots denied"
            puts(@error) if @verbose
            fail(self)
          end
        }
        robots.errback {
          robots_cache[robots_url.to_s] = "" if robots_cache
          puts("Started fetching: #{current_uri}") if @verbose
          h = EM::HttpRequest.new(current_uri).get(options)
          h.callback(&_handle_uri_callback)
          h.errback {
            @http_client = h
            @error = h.error
            puts(@error) if @verbose
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

