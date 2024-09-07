import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    let form = req.form.get()
    let name = form.getString("name")
    await res.send("Welcome " & name)

proc handler2(req: Request, res: Response): Future[Response] {.async.} =
    let data = req.json.get()
    let name = data["name"].getStr
    await res.send(%*{"message": "Welcome " & name})

proc handler3(req: Request, res: Response): Future[Response] {.async.} =
    let files = req.files.get()
    let filename = files["file"].filename
    await res.send(filename)

let router = newRouter()
    .register(post("/form", handler))
    .register(post("/json", handler2))
    .register(post("/files", handler3))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
