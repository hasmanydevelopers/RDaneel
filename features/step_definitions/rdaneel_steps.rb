
Given /^a robots\.txt that allows RDaneel$/ do
  $server.mount(:path  => '/robots.txt', :status => 200,
                :body  => "User-agent: *\nDisallow: /cgi-bin/")
end

Given /^a robots\.txt that denies RDaneel$/ do
  $server.mount(:path  => '/robots.txt', :status => 200,
                :body  => "User-agent: *\nDisallow: /")
end

Given /^a HelloWorld url$/ do
  $server.mount(:path  => '/hello_world', :status => 200,
                :body  => "Hello World")
end

When /^I get the "([^\"]*)" url$/ do |url|
  EM.run do
    @r = RDaneel.new("http://127.0.0.1:3210/#{url}")
    @r.callback do
      EM.stop
    end
    @r.errback do
      EM.stop
    end
    @r.get
  end
end

Then /^I should get the content for HelloWorld url$/ do
  @r.http_client.response.should == "Hello World"
end

Then /^the http response code should be (\d+)$/ do |code|
  @r.http_client.response_header.status.should == code.to_i
end

Then /^I should get (\d+) redirects$/ do |redirects_count|
  @r.redirects.size.should == redirects_count.to_i
end

Then /^The requests sequence should be:$/ do |expected_requests|
  current_requests = []
  $server.requests.each {|req| current_requests << [req[:status].to_s, req[:path]]}
  expected_requests.diff!(current_requests)
end

Then /^I should get a robots\.txt denied error code$/ do
  @r.error.should == "Robots are not allowed"
end

