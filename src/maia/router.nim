import tables, options
import chronos/apps/http/httpserver
import handler, filter, middlewares
import http/[path, request, response]

type
    Route* = tuple[path: string, methods: seq[HttpMethod], handler: Handler]
    Router* = ref object
        routes*: Table[string, Route]
        errorHandler*: ErrorHandler

    RouteError* = object of ValueError

proc newRouter*(): Router =
    new(result)
    result.routes = initTable[string, Route]()
    result.errorHandler = defaultErrorHandler

proc getRoute*(r: Router, path: string): Option[Route] =
    if r.routes.hasKey(path):
        return some(r.routes[path])

    for rpath, route in r.routes:
        if rpath.matchPath(path):
            return some(route)
    none(Route)

proc getRoutes*(r: Router): seq[Route] =
    result = @[]
    for path, route in r.routes:
        result.add(route)

proc register*(r: Router, route: Route): Router =
    result = r
    if not r.routes.hasKey(route.path):
        r.routes[route.path] = route
    else:
        raise newException(RouteError, "The path '" & route.path & "' is already registered.")

proc update*(r: Router, route: Route): Router =
    result = r
    if r.routes.hasKey(route.path):
        r.routes[route.path] = route

proc extends*(r: Router, router: Router): Router =
    result = r
    for route in router.getRoutes:
        discard r.register(route)

proc remove*(r: Router, path: string): Router =
    result = r
    r.routes.del(path)

proc setErrHandler*(r: Router, errHandler: ErrorHandler): Router =
    result = r
    result.errorHandler = errHandler

proc apply*(r: Route, middleware: Middleware): Route =
    let handler = proc(nReq: Request, nRes: Response): Future[Response] {.async.} =
        await middleware(nReq, nRes, r.handler)
    result = (r.path, r.methods, handler)

proc apply*(r: Router, middleware: Middleware): Router =
    result = r
    for path, route in r.routes:
        r.routes[path] = route.apply(middleware)

proc setFilter*(r: Route, filter: Filter): Route =
    let middleware = proc (req: Request, res: Response, next: Handler): Future[Response] {.async.} =
        if filter.check(req):
            await r.handler(req, res)
        else:
            await res.setStatus(filter.code)
                .send(filter.body)
    r.apply(middleware)

proc setFilter*(r: Router, filter: Filter): Router =
    result = r
    for path, route in r.routes:
        r.routes[path] = route.setFilter(filter)

proc staticFile*(path: string, root: string): Route =
    result = (path, @[MethodGet], defaultStaticHandler(root))

proc get*(path: string, handler: Handler): Route =
    (path, @[MethodGet], handler)

proc put*(path: string, handler: Handler): Route =
    (path, @[MethodPut], handler)

proc post*(path: string, handler: Handler): Route =
    (path, @[MethodPost], handler)

proc patch*(path: string, handler: Handler): Route =
    (path, @[MethodPatch], handler)

proc options*(path: string, handler: Handler): Route =
    (path, @[MethodOptions], handler)

proc head*(path: string, handler: Handler): Route =
    (path, @[MethodHead], handler)

proc delete*(path: string, handler: Handler): Route =
    (path, @[MethodDelete], handler)
