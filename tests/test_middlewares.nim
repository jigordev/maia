import unittest
import ../src/maia

proc testMiddlewares*() =
    suite "Middlewares test":
        test "Middleware test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                res

            proc middleware(req: Request, res: Response, next: Handler): Future[Response] {.async.} =
                discard await next(req, res)
                await res.send("Test middleware")

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter()
                .register(get("/", handler)
                    .apply(middleware))

            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Test middleware" in responseBody