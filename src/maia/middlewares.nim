import handler
import http/[request, response]
import chronos/apps/http/httpserver

type
    MiddlewareError* = object of ValueError
    Middleware* = proc(req: Request, res: Response,
            next: Handler): Future[Response] {.async, gcsafe.}
