Feature: get a url using cache
  In order to fetch content from internet
  As a crawler
  I want to get a url respecting robots.txt rules

  Scenario: the url to fetch is redirected
    Given a cache for RDaneel
    And   a robots.txt that allows RDaneel
    And   a HelloWorld url
    And   a "/redirect_me" url that redirects 301 to "http://127.0.0.1:3210/redirect_me_again" url
    And   a "/redirect_me_again" url that redirects 302 to "/hello_world" url
    When  I get the "/redirect_me" url following a maximum of 3 redirects
    Then  I should get the content for HelloWorld url
    And   the http response code should be 200
    And   I should get 2 redirects
    And   The redirects sequence should be:
      | http://127.0.0.1:3210/redirect_me       |
      | http://127.0.0.1:3210/redirect_me_again |
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 301    | /redirect_me       |
      | 302    | /redirect_me_again |
      | 200    | /hello_world       |
    And    The cache for "http://127.0.0.1:3210/robots.txt" should be
      """
      User-agent: *
      Disallow: /cgi-bin/
      """

