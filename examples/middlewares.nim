import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Hello World!")

proc myMiddleware(req: Request, res: Response, next: Handler): Future[Response] {.async.} =
    echo "My Middleware"
    await next(req, res)

let router = newRouter()
    .register(get("/", handler)
        .apply(myMiddleware))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
