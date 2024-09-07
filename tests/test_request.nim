import unittest
import ../src/maia

proc testRequest*() =
    suite "Request tests":
        test "Request attributes test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                if req.httpMethod != MethodGet:
                    await res.send("Failed http method")
                elif req.version != HttpVersion11:
                    await res.send("Failed http version")
                elif req.getHeader("User-Agent") != "MaiaHttpClient":
                    await res.send("Failed request headers")
                elif req.getCookie("session") != "abc123":
                    await res.send("Failed request cookies")
                elif req.contentType != req.getHeader("Content-Type"):
                    await res.send("Failed content type")
                elif req.contentLength != 0:
                    await res.send("Failed content length")
                elif $req.uri != "/":
                    await res.send("Failed request uri")
                elif req.path != "/":
                    await res.send("Failed request path")
                elif req.scheme != "http":
                    await res.send("Failed url scheme")
                elif req.port == 0:
                    echo $req.port
                    await res.send("Failed port")
                elif req.host != "127.0.0.1":
                    await res.send("Failed request host")
                elif "127.0.0.1" notin req.remoteAddr:
                    await res.send("Failed remote address")
                elif req.secure:
                    await res.send("Failed secure request")
                else:
                    await res.send("Success")

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET / HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "Cookie: session=abc123;" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter().register(get("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "Success" in responseBody

        test "Request path args test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let name = req.args.get().getString("name")
                await res.send(name)

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET /John HTTP/1.1" & "\c\l" &
                            "Host: 127.0.0.1" & "\c\l" &
                            "User-Agent: MaiaHttpClient" & "\c\l" &
                            "Accept: */*" & "\c\l" &
                            "\c\l"
                
                let (_, data) = await testHttpClient(address, getData)
                responseBody = data

            let router = newRouter().register(get("/:name", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "John" in responseBody

        test "Request query test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let name = req.query.getString("name")
                await res.send(name)

            proc serverHook(address: TransportAddress) {.async.} =
                let getData = "GET /?name=John HTTP/1.1" & "\c\l" &
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
            check "John" in responseBody

        test "Request form test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let name = req.form.get().getString("name")
                await res.send(name)

            proc serverHook(address: TransportAddress) {.async.} =
                let postData = "POST / HTTP/1.1" & "\c\l" &
                                "Host: 127.0.0.1" & "\c\l" &
                                "User-Agent: MaiaHttpClient" & "\c\l" &
                                "Accept: */*" & "\c\l" &
                                "Content-Type: application/x-www-form-urlencoded" & "\c\l" &
                                "Content-Length: 9" & "\c\l" &
                                "\c\l" &
                                "name=John"

                let (_, data) = await testHttpClient(address, postData)
                responseBody = data

            let router = newRouter().register(post("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "John" in responseBody

        test "Request json test":
            var responseBody = ""

            proc handler(req: Request, res: Response): Future[Response] {.async.} =
                let name = req.json.get()["name"].getStr
                await res.send(name)

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

            let router = newRouter().register(post("/", handler))
            discard newHttpServer(router)
                .setConfig(Config(testing: true))
                .addStartServerHook(serverHook)
                .start()
            check "John" in responseBody