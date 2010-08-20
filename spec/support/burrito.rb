require 'socket'

class Burrito
  
  # Why does Burrito exist? Why didn't we used Webrick, or Mongrel, or Thin 
  # with Rack...? Specs failed at random, in different way in different machines
  # because of Thread related issues, it became a nightmare. So we fall back
  # to something we could completely control: A TCP socket :)

  STATUS_MESSAGES = {
    200 => 'OK',
    301 => 'Moved Permanently',
    302 => 'Found',
    302 => 'Not Found'
  }

  attr_reader :requests        

  def initialize
    @routes = {}
    @requests = []
  end

  def mount(opts)
    @routes[opts[:path]] = { :status => opts[:status],
                             :body => opts[:body],
                             :location => opts[:location] }
  end

  def reset
    @routes = {}
    @requests = []
  end

  def start
    @thread = Thread.new do 

      webserver = TCPServer.new('127.0.0.1', 3210)
      
      while session = webserver.accept
        request = session.gets
        path = '/' << request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '').chomp
        if @routes[path]
          status = @routes[path][:status]
          body = @routes[path][:body]
          location = @routes[path][:location]
        else
          status = 404
        end
        @requests.push( { :status => status, :path => path } )
        response =  "HTTP/1.1 #{status} #{STATUS_MESSAGES[status]}\r\n"
        response << "Server: burrito/0.0.1\r\n"
        response << "Content-Length: #{ body ? body.length : 0 }\r\n"
        response << "Content-Type: text/plain\r\n" if body
        response << "Location: #{location}\r\n" if location
        response << "Connection: close\r\n"
        response << "\r\n"
        response << "#{body}" if body
        session.print response
        session.close
      end  
          
    end
     
  end
     
  def shutdown
    @thread.terminate
  end
  
end


