import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.sendFile("filename.txt")

let router = newRouter()
    .register(get("/download", handler))
    .register(staticFile("/static", "staticfile.txt"))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()