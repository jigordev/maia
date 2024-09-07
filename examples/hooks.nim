import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Hello World!")

proc beforeRequest(req: Request) {.async.} =
    echo "Before request hook"

proc afterRequest(res: Response) {.async.} =
    echo "After request hook"

proc teardownRequest(exc: ref Exception) {.async.} =
    echo "Teardown request hook"

proc startServerHook(address: TransportAddress) {.async.} =
    echo "Server started"

proc stopServerHook(address: TransportAddress) {.async.} =
    echo "Server stopped"

let router = newRouter()
    .register(get("/", handler))

discard newHttpServer(router)
    .addBeforeRequest(beforeRequest)
    .addAfterRequest(afterRequest)
    .addTeardownRequest(teardownRequest)
    .addStartServerHook(startServerHook)
    .addStopServerHook(stopServerHook)
    .setConfig(Config(port: 5000))
    .start()
