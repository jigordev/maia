import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Authenticated!")

let token = "your_auth_token"

let authFilter = Filter(code: Http401, body: "Authorization token required!")
    .headerEqTo("Authorization", token)

let router = newRouter()
    .register(get("/", handler))
    .setFilter(authFilter)

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()