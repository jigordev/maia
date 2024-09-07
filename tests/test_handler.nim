import unittest
import ../src/maia

proc testHandler*() =
    suite "Handler tests":
        test "withArg test":
            proc handler(req: Request, res: Response, arg: string): Future[Response] {.async.} =
                await res.send(arg)

            check withArg(handler, "argument") is Handler

        test "defaultErrorHandler test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                raise newException(CatchableError, "Test default error handler")

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Internal Server Error" in responseBody

        test "debugErrorHandler test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                raise newException(CatchableError, "Test debug error handler")

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true, debug: true))
                .addStartServerHook(serverHook)
                .start()
            check "Test debug error handler" in responseBody

        test "defaultStaticHandler test":
            var responseBody = ""

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter()
                .register(staticFile("/", "tests/data/file.txt"))

            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Test file" in responseBody