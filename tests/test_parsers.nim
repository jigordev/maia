import unittest
import ../src/maia
import ../src/maia/http/parsers

proc testParsers*() =
    suite "parseCookies tests":
        test "parse single cookie":
            let cookie = parseCookie("session_id=abc123;")
            check cookie.getString("session_id") == "abc123"

        test "parse multiple cookies":
            let cookie = parseCookie("session_id=abc123; user_id=456;")
            check cookie.getString("session_id") == "abc123"
            check cookie.getString("user_id") == "456"

        test "handle extra spaces and tabs":
            let cookie = parseCookie(" session_id = abc123 ;   user_id = 456  ,")
            check cookie.getString("session_id") == "abc123"
            check cookie.getString("user_id") == "456"

        test "handle empty string":
            let cookie = parseCookie("")
            check cookie.isEmpty

    ### Add test parseBody