import maia

proc handler(req: Request, res: Response, message: string): Future[Response] {.async.} =
    await res.send(message)

let message = "Handler with arg"

let router = newRouter()
    .register(get("/", withArg(handler, message)))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
