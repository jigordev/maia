import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
  await res.send("Handler 1")

proc handler2(req: Request, res: Response): Future[Response] {.async.} =
  await res.send("Handler 2")

proc handler3(req: Request, res: Response): Future[Response] {.async.} =
  await res.send("Handler 3")

proc handler4(req: Request, res: Response): Future[Response] {.async.} =
  await res.send("Handler 4")

let router2 = newRouter()
  .register(get("/handle3", handler3))
  .register(get("/handler4", handler4))

let router = newRouter()
  .register(get("/handler", handler))
  .register(get("/handler2", handler2))
  .extends(router2)

discard newHttpServer(router)
  .setConfig(Config(port: 5000))
  .start()
