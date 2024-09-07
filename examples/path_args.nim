import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    let args = req.args.get()
    let name = args.getString("name")
    await res.send("Welcome " & name)

let router = newRouter()
    .register(get("/:name", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
