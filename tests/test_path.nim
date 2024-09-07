import unittest, re
import ../src/maia
import ../src/maia/http/path

proc testPath*() =
    suite "Tests for pathToRegex":
        test "Simple path without parameters":
            let path = "/users"
            let regex = pathToRegex(path)
            check find("/users", regex) != -1

        test "Path with a single parameter":
            let path = "/users/:id"
            let regex = pathToRegex(path)
            check find("/users/test", regex) != -1

        test "Path with multiple parameters":
            let path = "/users/:userId/posts/:postId"
            let regex = pathToRegex(path)
            check find("/users/test/posts/1234", regex) != -1

    suite "Tests for matchPath":
        test "Matching exact paths":
            check matchPath("/users", "/users") == true

        test "Non-matching paths":
            check matchPath("/users", "/admin") == false

        test "Matching path with parameter":
            check matchPath("/users/:id", "/users/123") == true

        test "Non-matching path with parameter":
            check matchPath("/users/:id", "/users/") == false

        test "Matching path with multiple parameters":
            check matchPath("/users/:userId/posts/:postId", "/users/123/posts/456") == true

        test "Non-matching path with multiple parameters":
            check matchPath("/users/:userId/posts/:postId", "/users/123/comments/456") == false

    suite "Tests for parseArgs":
        test "No parameters in path":
            let expectedPath = "/users"
            let actualPath = "/users"
            let result = parseArgs(expectedPath, actualPath)
            check result.isNone

        test "Single parameter in path":
            let expectedPath = "/users/:id"
            let actualPath = "/users/123"
            let result = parseArgs(expectedPath, actualPath)
            check result.isSome
            check result.get().getString("id") == "123"

        test "Multiple parameters in path":
            let expectedPath = "/users/:userId/posts/:postId"
            let actualPath = "/users/123/posts/456"
            let result = parseArgs(expectedPath, actualPath)
            check result.isSome
            check result.get().getString("userId") == "123"
            check result.get().getString("postId") == "456"

        test "Path length mismatch":
            let expectedPath = "/users/:userId"
            let actualPath = "/users/123/posts"
            let result = parseArgs(expectedPath, actualPath)
            check result.isNone

        test "No parameter extraction when there is no colon":
            let expectedPath = "/users"
            let actualPath = "/users"
            let result = parseArgs(expectedPath, actualPath)
            check result.isNone