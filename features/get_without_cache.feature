Feature: get a url without using cache
  In order to fetch content from internet
  As a crawler
  I want to get a url respecting robots.txt rules

  Scenario: a robots.txt exists allowing RDaneel's user-agent
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    When  I get the "/hello_world" url following a maximum of 1 redirects
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
    When  I get the "/hello_world" url following a maximum of 1 redirects
    Then  I should get a "Robots are not allowed" error
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path         |
      | 200    | /robots.txt  |

  Scenario: the url to fetch is redirected
    Given a robots.txt that allows RDaneel
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
      | 200    | /robots.txt        |
      | 302    | /redirect_me_again |
      | 200    | /robots.txt        |
      | 200    | /hello_world       |

  Scenario: the url to fetch exceeds the maximum redirects specifieds
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    And   a "/redirect_me" url that redirects 301 to "http://127.0.0.1:3210/redirect_me_again" url
    And   a "/redirect_me_again" url that redirects 302 to "/hello_world" url
    When  I get the "/redirect_me" url following a maximum of 1 redirects
    Then  I should get a "Exceeded maximum number of redirects: 1" error
    And   I should get 1 redirects
    And   The redirects sequence should be:
      | http://127.0.0.1:3210/redirect_me       |
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 301    | /redirect_me       |
      | 200    | /robots.txt        |
      | 302    | /redirect_me_again |

  Scenario: the url to fetch has an infinte redirect
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    And   a "/redirect_me" url that redirects 302 to "/redirect_me_again" url
    And   a "/redirect_me_again" url that redirects 302 to "/redirect_me" url
    When  I get the "/redirect_me" url following a maximum of 2 redirects
    Then  I should get a "Infinite redirect detected for: http://127.0.0.1:3210/redirect_me" error
    And   I should get 2 redirects
    And   The redirects sequence should be:
      | http://127.0.0.1:3210/redirect_me       |
      | http://127.0.0.1:3210/redirect_me_again |
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 302    | /redirect_me       |
      | 200    | /robots.txt        |
      | 302    | /redirect_me_again |

  Scenario: the url to fetch redirects to not found url
    Given a robots.txt that allows RDaneel
    And   a "/redirect_me" url that redirects 302 to "/not_found" url
    When  I get the "/redirect_me" url following a maximum of 2 redirects
    Then  I should get a "Not success neither redirect" error
    And   I should get 1 redirects
    And   The redirects sequence should be:
      | http://127.0.0.1:3210/redirect_me |
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 302    | /redirect_me       |
      | 200    | /robots.txt        |
      | 404    | /not_found         |


  Scenario: robots.txt doesn't exists
    Given a HelloWorld url
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
      | 404    | /robots.txt        |
      | 301    | /redirect_me       |
      | 404    | /robots.txt        |
      | 302    | /redirect_me_again |
      | 404    | /robots.txt        |
      | 200    | /hello_world       |

  Scenario: the url to fetch redirects to a malformed url (format handled by em-http-request)
    Given a robots.txt that allows RDaneel
    And   a "/redirect_me" url that redirects 302 to "http://malformed:url" url
    When  I get the "/redirect_me" url following a maximum of 2 redirects
    Then  I should get a "Location header format error" error
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 302    | /redirect_me       |

  Scenario: the url to fetch redirects to a malformed url (format not handled by em-http-request 0.2.10)
    Given a robots.txt that allows RDaneel
    And   a "/redirect_me" url that redirects 302 to "http:/malformed:url" url
    When  I get the "/redirect_me" url following a maximum of 2 redirects
    Then  I should get a "Location header format error" error
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 302    | /redirect_me       |

  Scenario: the url to fetch is redirected to unreacheable port
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    And   a "/redirect_me" url that redirects 301 to "http://127.0.0.1:3211/unreacheable" url
    When  I get the "/redirect_me" url following a maximum of 3 redirects
    Then  I should get a "An error occurred when fetching http://127.0.0.1:3211/unreacheable" error
    And   I should get 1 redirects
    And   The redirects sequence should be:
      | http://127.0.0.1:3210/redirect_me       |
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 301    | /redirect_me       |

  Scenario: the url to fetch is redirected to unreacheable host
    Given a robots.txt that allows RDaneel
    And   a HelloWorld url
    And   a "/redirect_me" url that redirects 301 to "http://wrongserver/unreacheable" url
    When  I get the "/redirect_me" url following a maximum of 3 redirects
    Then  I should get a "unable to resolve server address" error
    And   I should get 1 redirects
    And   The redirects sequence should be:
      | http://127.0.0.1:3210/redirect_me       |
    And   The requests sequence should be:
      | status | path               |
      | 200    | /robots.txt        |
      | 301    | /redirect_me       |

  Scenario: the robots.txt for the url to fetch is redirected to unreacheable host:port
    Given a "/robots.txt" url that redirects 301 to "http://127.0.0.1:3211/unreacheable" url
    And   a HelloWorld url
    When  I get the "/hello_world" url following a maximum of 3 redirects
    Then  I should get the content for HelloWorld url
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path               |
      | 301    | /robots.txt        |
      | 200    | /hello_world       |

  Scenario: the robots.txt for the url to fetch is redirected to unreacheable host
    Given a "/robots.txt" url that redirects 301 to "http://wrongserver/unreacheable" url
    And   a HelloWorld url
    When  I get the "/hello_world" url following a maximum of 3 redirects
    Then  I should get the content for HelloWorld url
    And   I should get 0 redirects
    And   The requests sequence should be:
      | status | path               |
      | 301    | /robots.txt        |
      | 200    | /hello_world       |

