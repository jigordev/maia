import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.error(Http400, "Return error message")

proc errorHandler(req: Request, res: Response, exc: ref Exception): Future[Response] {.async.} =
    await res.setStatus(Http500).send("An error occurred")

let router = newRouter()
    .setErrHandler(errorHandler)
    .register(get("/", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
