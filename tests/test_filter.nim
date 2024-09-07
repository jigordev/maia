import unittest, uri
import ../src/maia

proc testFilter*() =
    suite "Filter Tests":
        test "Filter check passes with no validators":
            let req = Request(uri: parseUri("/test"))
            var filter = Filter()
            check filter.check(req) == true

        test "Filter check fails with failing validator":
            let req = Request(uri: parseUri("/test"))
            var filter = Filter().urlContains("/prod")
            check filter.check(req) == false

        test "Filter check passes with passing validator":
            let req = Request(uri: parseUri("/test"))
            var filter = Filter().urlContains("/test")
            check filter.check(req) == true

        test "Filter with multiple validators, one fails":
            let req = Request(uri: parseUri("/test"))
            var filter = Filter().urlContains("/test").urlContains("/prod")
            check filter.check(req) == false

        test "Filter urlContains method":
            let req = Request(uri: parseUri("/test/contains"))
            var filter = Filter().urlContains("contains")
            check filter.check(req) == true

        test "Filter urlExcludes method":
            let req = Request(uri: parseUri("/test/exclude"))
            var filter = Filter().urlExcludes("not_here")
            check filter.check(req) == true

        test "Filter isSecure method":
            let req = Request(secure: true)
            var filter = Filter().isSecure()
            check filter.check(req) == true

            let req2 = Request(secure: false)
            check filter.check(req2) == false

        test "Filter notSecure method":
            let req = Request(secure: false)
            var filter = Filter().notSecure()
            check filter.check(req) == true

            let req2 = Request(secure: true)
            check filter.check(req2) == false

        test "Filter queryContains method":
            var query = init(HttpTable)
            query.add("name", "value")
            let req = Request(query: query)
            var filter = Filter().queryContains("name")
            check filter.check(req) == true

        test "Filter queryExcludes method":
            var query = init(HttpTable)
            query.add("name", "value")
            let req = Request(query: query)
            var filter = Filter().queryExcludes("notname")
            check filter.check(req) == true

        test "Filter headersContains method":
            var headers = init(HttpTable)
            headers.add("X-Test", "present")
            let req = Request(headers: headers)
            var filter = Filter().headersContains("X-Test")
            check filter.check(req) == true

        test "Filter headersExcludes method":
            var headers = init(HttpTable)
            headers.add("X-Test", "present")
            let req = Request(headers: headers)
            var filter = Filter().headersExcludes("X-Missing")
            check filter.check(req) == true

        test "Filter cookiesContains method":
            var cookies = init(HttpTable)
            cookies.set("session", "abc123")
            let req = Request(cookies: cookies)
            var filter = Filter().cookiesContains("session")
            check filter.check(req) == true

        test "Filter cookiesExcludes method":
            var cookies = init(HttpTable)
            cookies.set("session", "abc123")
            let req = Request(cookies: cookies)
            var filter = Filter().cookiesExcludes("nosession")
            check filter.check(req) == true

        test "Filter raises FilterError on exception":
            let req = Request(uri: parseUri("/test"))
            var filter = Filter().custom(proc(req: Request): bool = raise newException(ValueError, "Invalid value"))
            var exceptionThrown = false
            try:
                discard filter.check(req)
            except FilterError:
                exceptionThrown = true
            check exceptionThrown

        test "Filter jsonContains method":
            var responseBody: string

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let data = req.json.get()
                await res.send($data)

            proc serverHook(address: TransportAddress) {.async.} =
                let postData = "POST / HTTP/1.1" & "\c\l" &
                                "Host: 127.0.0.1" & "\c\l" &
                                "User-Agent: MaiaHttpClient" & "\c\l" &
                                "Accept: */*" & "\c\l" &
                                "Content-Type: application/json" & "\c\l" &
                                "Content-Length: 16" & "\c\l" &
                                "\c\l" &
                                "{\"name\": \"John\"}"

                let (_, data) = await testHttpClient(address, postData)
                responseBody = data

            let router = newRouter()
                .register(post("/", handler))
                .setFilter(Filter().jsonContains("name"))

            discard newHttpServer(router)
                .setConfig(Config(port: 5000, testing: true))
                .addStartServerHook(serverHook)
                .start()
            
            check "{\"name\":\"John\"}" in responseBody

        test "Filter jsonExcludes method":
            var responseBody: string

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let data = req.json.get()
                await res.send($data)

            proc serverHook(address: TransportAddress) {.async.} =
                let postData = "POST / HTTP/1.1" & "\c\l" &
                                "Host: 127.0.0.1" & "\c\l" &
                                "User-Agent: MaiaHttpClient" & "\c\l" &
                                "Accept: */*" & "\c\l" &
                                "Content-Type: application/json" & "\c\l" &
                                "Content-Length: 16" & "\c\l" &
                                "\c\l" &
                                "{\"name\": \"John\"}"

                let (_, data) = await testHttpClient(address, postData)
                responseBody = data

            let router = newRouter()
                .register(post("/", handler))
                .setFilter(Filter().jsonExcludes("missing"))

            discard newHttpServer(router)
                .setConfig(Config(port: 5000, testing: true))
                .addStartServerHook(serverHook)
                .start()
            
            check "{\"name\":\"John\"}" in responseBody
