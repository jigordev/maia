import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    let name = req.query.getString("name")
    await res.send("Welcome " & name)

let router = newRouter()
    .register(get("/", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
