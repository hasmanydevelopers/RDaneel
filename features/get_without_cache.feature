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
      | 200 | /robots.txt |
      | 200 | /hello_world |

  Scenario: a robots.txt exists denying RDaneel's user-agent
    Given a robots.txt that denies RDaneel
    And   a HelloWorld url
    When  I get the "hello_world" url
    Then  I should get a robots.txt denied error code
    And   I should get 0 redirects
    And   The requests sequence should be:
      | 200 | /robots.txt |

