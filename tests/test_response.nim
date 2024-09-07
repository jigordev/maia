import unittest
import ../src/maia

proc testResponse*() =
    suite "Response tests":
        test "setStatus test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.setStatus(Http201).send("")

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
            check "201" in responseBody

        test "setHeader test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.setHeader("X-Test", "Testing").send("")

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
            check "Testing" in responseBody

        test "setCookie test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.setCookie("session", "abc123").send("")

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
            check "session=abc123" in responseBody

        test "send test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.send("Hello World!")

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
            check "Hello World!" in responseBody

        test "send json test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.send(%*{"message": "Hello World!"})

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
            check "{\"message\":\"Hello World!\"}" in responseBody

        test "redirect test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.redirect("https://google.com")

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
            check "Location: https://google.com" in responseBody

        test "error test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.error(Http400)

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
            check "Bad Request" in responseBody

        test "sendFile test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.sendFile("tests/data/file.txt")

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
            check "Test file" in responseBody

        test "render test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let message = "Hello World!"
                await res.render("<h1>{{ msg }}</h1>", {msg: message})

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
            check "<h1>Hello World!</h1>" in responseBody

        test "renderTemplate test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let message = "Hello World!"
                await res.renderTemplate("data/index.nimja", {msg: message})

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
            check "<h1>Hello World!</h1>" in responseBody

        test "stream test":
            var responseBody = ""
            var responseBody2 = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                await res.prepare()
                await res.write("Hello")
                await res.write("World!")
                await res.finish()
                res

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                
                let (_, data) = await testHttpClient(address, getData)
                let (_, data2) = await testHttpClient(address, getData)
                responseBody = data
                responseBody2 = data2

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Hello" in responseBody
            check "World!" in responseBody2