import chronos/apps/http/httpserver
import http/[request, response]
import errors

type
    HandlerWithArg[T] = proc(req: Request, res: Response, arg: T): Future[Response] {.gcsafe, async.}
    Handler* = proc(req: Request, res: Response): Future[Response] {.gcsafe, async.}

proc withArg*[T](handler: HandlerWithArg, arg: T): Handler =
    proc(req: Request, res: Response): Future[Response] {.gcsafe, async.} =
        discard handler(req, res, arg)

type
    ErrorHandler* = proc(req: Request, res: Response,
            error: ref Exception): Future[Response] {.gcsafe, async.}

proc debugErrorHandler*(req: Request, res: Response,
        error: ref Exception): Future[Response] {.async.} =
    let errorContent = debugException(error)
    await res.setStatus(Http500).send(errorContent)

proc defaultErrorHandler*(req: Request, res: Response,
        error: ref Exception): Future[Response] {.async.} =
    let errorContent = defaultError()
    await res.setStatus(Http500).send(errorContent)

proc defaultStaticHandler*(root: string): Handler =
    result = proc(req: Request, res: Response): Future[Response] {.async.} =
        await res.sendFile(filename=root, attachment=false)
