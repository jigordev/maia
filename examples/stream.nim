import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.prepare()
    await res.write("Chunked")
    await sleepAsync(5.seconds)
    await res.write("Stream")
    await res.finish()

proc handler2(req: Request, res: Response): Future[Response] {.async.} =
    await res.prepare(HttpResponseStreamType.SSE)
    await res.event("stream", "SSE Event")
    await sleepAsync(5.seconds)
    await res.event("stream", "Stream")
    await res.finish()

let router = newRouter()
    .register(get("/chunks", handler))
    .register(get("/event", handler2))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
