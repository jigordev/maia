import ./[
    test_server,
    test_router,
    test_utils,
    test_parsers,
    test_middlewares,
    test_handler,
    test_filter,
    test_errors,
    test_path,
    test_request,
    test_response
]

proc runTests() =
    testServer()
    testRouter()
    testUtils()
    testParsers()
    testMiddlewares()
    testHandler()
    testFilter()
    testErrors()
    testPath()
    testRequest()
    testResponse()

when isMainModule:
    runTests()