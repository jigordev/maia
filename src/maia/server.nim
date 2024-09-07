import chronos/apps/http/httpserver
import options, times
import router, handler
import http/[request, response]

type
    Config* = object
        address*: string = "127.0.0.1"
        port*: int = 5000
        maxConnections*: int = 25_600
        backlogSize*: int = 2048
        serverFlags*: set[HttpServerFlags] = {}
        socketFlags*: set[ServerFlags] = {ServerFlags.TcpNoDelay,
                ServerFlags.ReuseAddr}
        httpHeadersTimeout*: int = 60_000
        bufferSize*: int = 16_384
        maxHeadersSize*: int = 8192
        maxRequestBodySize*: int = 16_777_216
        testing*: bool = false
        debug*: bool = false

    RequestHookError* = object of ValueError
    ServerHookError* = object of ValueError
    RequestHook* = proc(req: Request) {.async.}
    ResponseHook* = proc(res: Response) {.async.}
    TeardownHook* = proc(exc: ref Exception) {.async.}
    ServerHook* = proc(address: TransportAddress) {.async.}

    HttpServerError* = object of ValueError
    HttpServer* = ref object
        config*: Config
        router*: Router
        beforeRequestHooks*: seq[RequestHook]
        afterRequestHooks*: seq[ResponseHook]
        teardownRequestHooks*: seq[TeardownHook]
        startServerHooks*: seq[ServerHook]
        stopServerHooks*: seq[ServerHook]

proc newHttpServer*(router: Router): HttpServer =
    new(result)
    result.router = router

proc addBeforeRequest*(s: HttpServer, hook: RequestHook): HttpServer =
    result = s
    if hook notin s.beforeRequestHooks:
        s.beforeRequestHooks.add(hook)

proc addAfterRequest*(s: HttpServer, hook: ResponseHook): HttpServer =
    result = s
    if hook notin s.afterRequestHooks:
        s.afterRequestHooks.add(hook)

proc addTeardownRequest*(s: HttpServer, hook: TeardownHook): HttpServer =
    result = s
    if hook notin s.teardownRequestHooks:
        s.teardownRequestHooks.add(hook)

proc addStartServerHook*(s: HttpServer, hook: ServerHook): HttpServer =
    result = s
    if hook notin s.startServerHooks:
        s.startServerHooks.add(hook)

proc addStopServerHook*(s: HttpServer, hook: ServerHook): HttpServer =
    result = s
    if hook notin s.stopServerHooks:
        s.stopServerHooks.add(hook)

proc logging(s: HttpServer, req: Request, res: Response) =
    let currentTime = now()
    let formattedTime = currentTime.format("[yyyy/MM/dd HH:mm:ss]")
    let address = $s.config.address & ":" & $s.config.port
    echo address & " " & formattedTime & " " &
            $req.httpMethod & " " & req.uri.path & " " & $res.status

proc runHooks(hooks: seq[auto], arg: auto): Future[void] {.async.} =
    for hook in hooks:
        try:
            await hook(arg)
        except Exception as exc:
            raise ServerHookError.newException(exc.msg)

proc startServer(s: HttpServer) {.async: (raises: [CatchableError]).} =
    var
        routeException: ref Exception
        req: Request
        res: Response
    
    proc mainHandler(reqfence: RequestFence): Future[HttpResponseRef] {.async: (
        raises: [CancelledError]).} =
        if reqfence.isErr():
            return defaultResponse()

        let request = reqfence.get()

        try:
            let routeOpt = s.router.getRoute(request.uri.path)

            if routeOpt.isNone:
                return await request.respond(Http404, $Http404)
            
            let route = routeOpt.get()
            
            if request.meth notin route.methods:
                return await request.respond(Http405, $Http405)
                
            req = await newRequest(request, route.path)
            res = newResponse(request)

            if s.beforeRequestHooks.len != 0:
                await runHooks(s.beforeRequestHooks, req)

            try:
                res = await route.handler(req, res)
                if s.afterRequestHooks.len != 0:
                    await runHooks(s.afterRequestHooks, res)
            except Exception as exc:
                routeException = exc
                if s.config.debug:
                    res = await debugErrorHandler(req, res, exc)
                else:
                    res = await s.router.errorHandler(req, res, exc)
            
            if not s.config.testing:
                s.logging(req, res)
            
            if s.teardownRequestHooks.len != 0:
                await runHooks(s.teardownRequestHooks, routeException)
        except CatchableError:
            discard request.respond(Http500, $Http500, init(HttpTable))

    let address = initTAddress(s.config.address, s.config.port)

    let sRes = HttpServerRef.new(
        address = address,
        maxConnections = s.config.maxConnections,
        backlogSize = s.config.backlogSize,
        serverFlags = s.config.serverFlags,
        socketFlags = s.config.socketFlags,
        httpHeadersTimeout = timer.milliseconds(s.config.httpHeadersTimeout),
        bufferSize = s.config.bufferSize,
        maxHeadersSize = s.config.maxHeadersSize,
        maxRequestBodySize = s.config.maxRequestBodySize,
        processCallback = mainHandler
    )

    if not sRes.isOk():    
        raise HttpServerError.newException("Unable to start HTTP server")
    
    let server = sRes.get()
    server.start()

    if not s.config.testing:
        echo "Maia app running on ", address

    if s.startServerHooks.len != 0:
        await runHooks(s.startServerHooks, address)

    try:
        if not s.config.testing:
            await server.join()
    except CancelledError:
        discard
    finally:
        await server.stop()
        await server.closeWait()
        if s.stopServerHooks.len != 0:
            await runHooks(s.stopServerHooks, address)

proc setConfig*(s: HttpServer, config: Config): HttpServer =
    result = s
    s.config = config

proc start*(s: HttpServer): HttpServer =
    waitFor(s.startServer())
