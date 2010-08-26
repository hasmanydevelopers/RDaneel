
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

Given /^a "([^"]*)" url that redirects (\d+) to "([^"]*)" url$/ do |url, status, redirected_to|
  $server.mount(:path  => url, :status => status.to_i,
                :location  => redirected_to)
end

When /^I get the "([^"]*)" url following a maximum of (\d+) redirects$/ do |url, max_redirects|
  EM.run do
    @r = RDaneel.new("#{HOST}#{url}")
    @r.callback do
      EM.stop
    end
    @r.errback do
      EM.stop
    end
    @r.get(:redirects => max_redirects)
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

Then /^The requests sequence should be:$/ do |expected_table|
  expected_requests = []
  expected_table.hashes.each do |hash|
    expected_requests << {:status => hash[:status].to_i,
                          :path => hash[:path]}
  end
  $server.requests.should == expected_requests
end

Then /^The redirects sequence should be:$/ do |expected_redirects|
  @r.redirects.should == expected_redirects.raw.flatten
end

Then /^I should get a "([^"]*)" error$/ do |error_message|
  @r.error.should == error_message
end

