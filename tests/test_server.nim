import unittest
import ../src/maia

proc testServer*() =
    suite "Server test":
        test "before request hook test":
            var called = false

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                discard                

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                discard await testHttpClient(address, getData)

            proc beforeRequest(req: Request) {.async.} =
                called = true

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .addBeforeRequest(beforeRequest)
                .start()
            check (called)

        test "after request hook test":
            var called = false

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                discard                

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                discard await testHttpClient(address, getData)

            proc afterRequest(res: Response) {.async.} =
                called = true

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .addAfterRequest(afterRequest)
                .start()
            check (called)

        test "teardown request hook test":
            var called = false

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                raise newException(CatchableError, "Error")

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                discard await testHttpClient(address, getData)

            proc teardownRequest(exc: ref Exception) {.async.} =
                called = true

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .addTeardownRequest(teardownRequest)
                .start()
            check (called)

        test "server hooks test":
            var called = false
            var called2 = false

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                raise newException(CatchableError, "Error")

            proc startServerHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                called = true
                discard await testHttpClient(address, getData)

            proc stopServerHook(address: TransportAddress) {.async.} =
                called2 = true

            proc teardownRequest(exc: ref Exception) {.async.} =
                called = true

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(startServerHook)
                .addStopServerHook(stopServerHook)
                .addTeardownRequest(teardownRequest)
                .start()
            check (called and called2)

        test "Invalid method test":
            var responseBody = ""
            
            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                discard                

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter().register(post("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Method Not Allowed" in responseBody

        test "Not found test":
            var responseBody = ""
            
            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                discard                

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter().register(get("/abc", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Not Found" in responseBody