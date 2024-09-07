import maia

proc handler(req: Request, res: Response: Future[Response] {.async.} =
    await res.send("Hello World!")

let router = newRouter()
    .register(get("/", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
