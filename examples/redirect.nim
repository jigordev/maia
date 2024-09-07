import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.redirect("/endpoint")

proc handler2(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Redirected!")

let router = newRouter()
    .register(get("/", handler))
    .register(get("/endpoint", handler2))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
