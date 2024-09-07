# Maia - Web Framework for Nim

**Maia** is a simple and powerful asynchronous web framework written in Nim, designed to build fast and scalable web applications. It provides routing, middleware support, filters, hooks, file handling, and more.

## Features

- **Routing**: Define routes and handlers easily.
- **Middlewares**: Apply custom middlewares to routes.
- **Asynchronous**: Built with asynchronous execution in mind.
- **Stream Support**: Send chunked data or Server-Sent Events (SSE).
- **Request Hooks**: Pre- and post-processing hooks for custom behavior.
- **Filters**: Apply request filters like authentication.
- **Static Files**: Serve static files or send specific files for download.
- **Error Handling**: Custom error handlers to manage exceptions.
- **Multiple Routers**: Support for extending routers.

## Getting Started

### Installation

1. Install the Nim language from [nim-lang.org](https://nim-lang.org).
2. Install Maia by cloning the repository or using a package manager (if available).

### Hello World Example

```nim
import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Hello World!")

let router = newRouter()
    .register(get("/", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
```

This simple example sets up a web server on port 5000 that returns "Hello World!" for requests to the root route (`/`).

### Redirect Example

```nim
import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.redirect("/endpoint")

proc handler2(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Redirected!")

let router = newRouter()
    .register(get("/", handler))
    .register(get("/endpoint", handler2))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
```

This example redirects requests from `/` to `/endpoint`.

### Handling Query Parameters

```nim
import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    let name = req.query.getString("name")
    await res.send("Welcome " & name)

let router = newRouter()
    .register(get("/", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
```

Extract query parameters from the URL and respond accordingly.

### Handling POST Requests

```nim
import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    let form = req.form.get()
    let name = form.getString("name")
    await res.send("Welcome " & name)

let router = newRouter()
    .register(post("/form", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
```

Handle `POST` requests, process form data, and send a response.

### Middleware Example

```nim
import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.send("Hello World!")

proc myMiddleware(req: Request, res: Response, next: Handler): Future[Response] {.async.} =
    echo "Middleware executed!"
    await next(req, res)

let router = newRouter()
    .register(get("/", handler).apply(myMiddleware))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
```

Add middleware to log requests or manipulate the request/response pipeline.

### Streams and Server-Sent Events (SSE)

```nim
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
```

Handle chunked responses and Server-Sent Events (SSE) for real-time data streaming.

### Filters (Authentication Example)

```nim
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
```

Apply request filters for authentication or other request validation.

### Error Handling Example

```nim
import maia

proc handler(req: Request, res: Response): Future[Response] {.async.} =
    await res.error(Http400, "Bad Request")

proc errorHandler(req: Request, res: Response, exc: ref Exception): Future[Response] {.async.} =
    await res.setStatus(Http500).send("An error occurred")

let router = newRouter()
    .setErrHandler(errorHandler)
    .register(get("/", handler))

discard newHttpServer(router)
    .setConfig(Config(port: 5000))
    .start()
```

Handle errors gracefully with custom error handlers.

## Conclusion

Maia makes it easy to develop fast, flexible, and scalable web applications in Nim. With support for routing, middleware, filters, and more, it is a lightweight framework that gives you full control over your web services.