Feature: get a url without using cache
  In order to fetch content from internet
  As a crawler
  I want to get a url respecting robots.txt rules

  Scenario: a robots.txt exists allowing RDaneel's user-agent
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    When  I get the "hello_world" url
    Then  I should get the content for HelloWorld url
    And   the http response code should be 200
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path         |
      | 200    | /robots.txt  |
      | 200    | /hello_world |

  Scenario: a robots.txt exists denying RDaneel's user-agent
    Given a robots.txt that denies RDaneel
    And   a HelloWorld url
    When  I get the "hello_world" url
    Then  I should get a robots.txt denied error code
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path         |
      | 200    | /robots.txt  |

  Scenario: the desire url to fecth is redirected
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    And   a "/redirect_me" url that redirects absolutely to "/redirect_me_again" url
    And   a "/redirect_me_again" url that redirects relatively to "/hello_world" url
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
      | 200    | /robots.txt        |
      | 302    | /redirect_me_again |
      | 200    | /robots.txt        |
      | 200    | /hello_world       |

