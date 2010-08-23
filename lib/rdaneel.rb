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
    @hash = @uri.hash if @verbose
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
        verbose("Succeded fetching: #{current_uri}", h, :status, :response)
        succeed(self)
      elsif redirected?(h)
        if @redirects.size >= max_redirects
          @http_client = h
          @error = "Exceeded maximum number of redirects: #{max_redirects}"
          verbose(@error, h, :status, :response)          
          fail(self)
          return
        end
        begin
          @redirects << current_uri.to_s
          current_uri = redirect_url(h, current_uri)
          verbose("Redirected to: #{current_uri.to_s} from: #{@redirects[-1]}", h, :status, :response)                    
          if @redirects.include?(current_uri.to_s)
            @http_client = h
            @error = "Infinite redirect detected for: #{current_uri.to_s}"
            verbose(@error, h, :status, :response)          
            fail(self)
            return
          end
          _get.call
        rescue StandardError => se
          @http_client = h
          @error = "Malformed redirect url: #{se.message}\n#{se.backtrace.join("\n")}"
          verbose(@error, h, :status, :response)
          fail(self)
        end
      else
        # other error
        @http_client = h
        @error = "Not success neither redirect"
        verbose(@error, h, :status, :response)
        fail(self)
      end
    }
    _get = lambda {
      robots_url = robots_txt_url(current_uri)
      if robots_cache && robots_file = robots_cache[robots_url.to_s]
        verbose("Found cached robots.txt:\n#{robots_cache[robots_url.to_s]} for: #{current_uri}")
        if robots_allowed?(robots_file, useragent, robots_url, current_uri)
          verbose("Robots identified by user agent: #{useragent} are allowed to access: #{current_uri}")
          begin
            h = EM::HttpRequest.new(current_uri).get(options)
            verbose("Started fetching: #{current_uri}",h,:request)
            h.callback(&_handle_uri_callback)
            h.errback {
              @http_client = h
              @error = h.error
              verbose("#{@error} for: #{current_uri}",h,:status,:response)
              fail(self)
            }
          rescue StandardError => se
            @http_client = EM::HttpClient.new("")
            @error = "#{se.message}\n#{se.backtrace.inspect}"
            verbose("For: #{current_uri} something went wrong: #{@error}")
            fail(self)
          end
        else
          @http_client = EM::HttpClient.new("")
          @error = "Robots are not allowed"
          verbose("#{@error} to access: #{current_uri} when identified by user agent: #{useragent}")
          fail(self)
        end
      else
        robots_url = robots_txt_url(current_uri)
        robots = EM::HttpRequest.new(robots_url).get(:redirects => 2) # get the robots.txt following redirects
        verbose("Started fetching robots.txt from: #{robots_url} for: #{current_uri}",robots,:request) 
        robots.callback {
          robots_file = robots.response
          verbose("Found robots.txt at #{robots_url}:\n#{robots_file}")
          robots_cache[robots_txt_url(robots_url).to_s] = robots_file if robots_cache
          if robots_allowed?(robots_file, useragent, robots_url, current_uri)
            verbose("Robots identified by user agent: #{useragent} are allowed to access: #{current_uri}")
            begin
              h = EM::HttpRequest.new(current_uri).get(options)
              verbose("Started fetching: #{current_uri}",h,:request)
              h.callback(&_handle_uri_callback)
              h.errback {
                @http_client = h
                @error = h.error
                verbose("#{@error} for: #{current_uri}", h, :status, :response)
                fail(self)
              }
            rescue StandardError => se
              @http_client = EM::HttpClient.new("")
              @error = "#{se.message}\n#{se.backtrace.inspect}"
              verbose("For: #{current_uri} something went wrong: #{@error}")
              fail(self)
            end
          else
            @http_client = EM::HttpClient.new("")
            @error = "Robots are not allowed"
            verbose("#{@error} to access: #{current_uri} when identified by user agent: #{useragent}")
            fail(self)
          end
        }
        robots.errback {
          verbose("Failed to fetch robots.txt: from: #{robots_url} for: #{current_uri}", robots, :status, :response)
          robots_cache[robots_url.to_s] = "" if robots_cache
          h = EM::HttpRequest.new(current_uri).get(options)
          verbose("Started fetching: #{current_uri}",h,:request)
          h.callback(&_handle_uri_callback)
          h.errback {
            @http_client = h
            @error = h.error
            verbose("#{@error} for: #{current_uri}", h, :status, :response)
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

  def verbose(message, client = nil, *args)
    return unless @verbose
    message.each { |l| hashed_puts('*', l) }
    args.each do |a|
      case a
        when :status
          if client.response_header.status == 0
            hashed_puts('< Status:', '0 (timeout)')
          else
            hashed_puts('< Status:', client.response_header.status)        
          end
        when :request  # this is a options hash
          headers = client.options[:head]
          headers.each { |k,v| hashed_puts('>', "#{k}: #{v}") } if headers
        when :response # this is an array
          client.response_header.each { |r| hashed_puts('<', "#{r[0]}: #{r[1]}") }
      end
    end
  end
  
  private
  
  def hashed_puts( prefix, message )
    $stdout.puts("[#{@hash}] [#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}] #{prefix} #{message}")  
  end

end

