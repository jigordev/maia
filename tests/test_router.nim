import unittest
import ../src/maia

proc testHandler(req: Request, res: Response): Future[Response] {.async.} =
    echo "Test handler"

proc testHandler2(req: Request, res: Response): Future[Response] {.async.} =
    echo "Test handler 2"

proc testErrorHandler*(req: Request, res: Response,
        error: ref Exception): Future[Response] {.async.} =
    echo "Test error handler"

proc testMiddleware(req: Request, res: Response, next: Handler): Future[Response] {.async.} =
    echo "Test middleware"
    await next(req, res)

proc testRouter*() =
    suite "Router tests":
        test "newRouter test":
            let router = newRouter()
            check router is Router
            check router.routes is Table[string, Route]

        test "getRoute tests":
            let route = get("/", testHandler)
            let router = newRouter()
                .register(route)
            check router.getRoute("/").isSome
            check router.getRoute("/").get() == route

        test "getRoutes tests":
            let route = get("/", testHandler)
            let router = newRouter()
                .register(route)
            check router.getRoutes().len == 1
            check router.getRoutes()[0] == route

        test "register tests":
            let route = get("/", testHandler)
            let router = newRouter()
                .register(route)
            var registered = false
            try:
                discard router.register(route)
                registered = true
            except CatchableError:
                discard
            check router.getRoute("/").isSome and router.getRoute("/").get() == route
            check (not registered)

        test "update tests":
            let route = get("/", testHandler)
            let route2 = get("/", testHandler2)
            let router = newRouter()
                .register(route)
                .update(route2)
            check router.getRoute("/").isSome and router.getRoute("/").get() == route2

        test "extends tests":
            let route = get("/", testHandler)
            let route2 = get("/2", testHandler2)
            let router = newRouter()
                .register(route)
            let router2 = newRouter()
                .register(route2)
                .extends(router)
            check router2.getRoute("/").isSome and router.getRoute("/").get() == route

        test "remove tests":
            let route = get("/", testHandler)
            let router = newRouter()
                .register(route)
                .remove("/")
            check router.getRoute("/").isNone

        test "setErrHandler tests":
            let router = newRouter()
                .setErrHandler(testErrorHandler)
            check router.errorHandler == testErrorHandler

        test "route.apply tests":
            let route = get("/", testHandler)
            let middlewareRoute = route.apply(testMiddleware)
            let router = newRouter()
                .register(route)
            check router.getRoute("/").isSome and router.getRoute("/").get().handler != middlewareRoute.handler

        test "router.apply tests":
            let route = get("/", testHandler)
            let router = newRouter()
                .register(route)
                .apply(testMiddleware)
            check router.getRoute("/").isSome and router.getRoute("/").get().handler != route.handler

        test "route.setFilter tests":
            let filter = Filter(code: Http401, body: "Test filter")
            let route = get("/", testHandler)
            let filterRoute = route.setFilter(filter)
            let router = newRouter()
                .register(route)
            check router.getRoute("/").isSome and router.getRoute("/").get().handler != filterRoute.handler

        test "router.setFilter tests":
            let filter = Filter(code: Http401, body: "Test filter")
            let route = get("/", testHandler)
            let filterRoute = route.setFilter(filter)
            let router = newRouter()
                .register(route)
            check router.getRoute("/").isSome and router.getRoute("/").get().handler != filterRoute.handler

        test "staticFile tests":
            let route = staticFile("/", "data/file.txt")
            check route.methods == @[MethodGet] and route.handler is Handler

        test "get tests":
            let route = get("/", testHandler)
            check route.methods == @[MethodGet] and route.handler == testHandler

        test "put tests":
            let route = put("/", testHandler)
            check route.methods == @[MethodPut] and route.handler == testHandler

        test "post tests":
            let route = post("/", testHandler)
            check route.methods == @[MethodPost] and route.handler == testHandler

        test "patch tests":
            let route = patch("/", testHandler)
            check route.methods == @[MethodPatch] and route.handler == testHandler

        test "options tests":
            let route = options("/", testHandler)
            check route.methods == @[MethodOptions] and route.handler == testHandler

        test "head tests":
            let route = head("/", testHandler)
            check route.methods == @[MethodHead] and route.handler == testHandler

        test "delete tests":
            let route = delete("/", testHandler)
            check route.methods == @[MethodDelete] and route.handler == testHandler