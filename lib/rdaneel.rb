require 'em-http'
require 'robot_rules'

class RDaneel

  class << self
    def robots_cache=(klass, options={})
      @robots_cache = klass.new(options)
    end

    def robots_cache
      @robots_cache
    end
  end

  def initialize(uri)
    @uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri)
  end

  def robots_cache
    self.class.robots_cache
  end

  #
  # The same em-http-request options apply here.
  # But when following redirects the method don't check the intermediate robots.txt just the first one.
  #
  def get(options = {}, &blk)
    useragent = "RDaneel"
    if options[:head]
      options[:head].keys.each do |k|
        useragent = options[:head][k] if k.to_s.downcase == "user-agent"
      end
    end
    if robots_cache && robots_file = robots_cache.get(robots_txt_url)
      raise Net::DisobeyingRobotsTxt unless robots_allowed?(robots_file, useragent)
      http = EventMachine::HttpRequest.new(@uri).get(options)
      http.callback {blk.call(http)}
      http.errback {blk.call(http)}
    else
      robots = EventMachine::HttpRequest.new(robots_txt_url).get
      robots.callback {
        robots_file = robots.response
        robots_cache.put(robots_txt_url, robots_file) if robots_cache
        raise Net::DisobeyingRobotsTxt unless robots_allowed?(robots_file, useragent)
        http = EventMachine::HttpRequest.new(@uri).get(options)
        http.callback {blk.call(http)}
        http.errback {blk.call(http)}
      }
      robots.errback {
        http = EventMachine::HttpRequest.new(@uri).get(options)
        http.callback {blk.call(http)}
        http.errback {blk.call(http)}
      }
    end
  end

  protected

  def robots_allowed?(robots_file, useragent)
    rules = RobotRules.new(useragent)
    rules.parse(@uri.to_s, robots_file)
    rules.allowed? @uri.to_s
  end

  def robots_txt_url
    location = if @uri.port == 80
      @uri.host
    else
      "#{@uri.host}:#{@uri.port}"
    end
    "http://#{location}/robots.txt"
  end

end

