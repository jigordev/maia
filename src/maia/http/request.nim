import path, parsers
import strutils, uri, json, options
import chronos/apps/http/httpserver

type
  Request* = ref object
    nativeReq: HttpRequestRef
    httpMethod*: HttpMethod
    version*: HttpVersion
    headers*: HttpTable
    args*: Option[HttpTable]
    cookies*: HttpTable
    contentType*: string
    contentLength*: int
    uri*: Uri
    path*: string
    query*: HttpTable
    scheme*: string
    port*: int
    host*: string
    remoteAddr*: string
    secure*: bool
    data*: seq[byte]
    body*: string
    form*: Option[HttpTable]
    files*: Option[FileTable]
    json*: Option[JsonNode]

proc newRequest*(req: HttpRequestRef, path: string): Future[Request] {.async.} =
  new(result)
  result.nativeReq = req
  result.version = req.version
  result.httpMethod = req.meth
  result.headers = req.headers
  result.contentType = req.headers.getString("Content-Type")
  result.contentLength = req.contentLength
  result.uri = req.uri
  result.path = req.rawPath
  result.query = req.query
  result.args = parseArgs(path, result.path)
  result.host = req.remoteAddress.host
  result.port = int(req.remoteAddress.port)
  result.remoteAddr = $req.remoteAddress
  result.scheme = req.scheme
  result.secure = req.scheme == "https"

  if req.headers.contains("Cookie"):
    for key, values in req.headers.items:
      if key.toLowerAscii() == "cookie":
        for value in values:
          result.cookies = parseCookie(value)
          break

  if req.hasBody and req.meth in PostMethods:
    let (data, form, files, json) = await req.parseBody()
    result.data = data
    result.body = data.bytesToString
    result.form = form
    result.files = files
    result.json = json

proc getHeader*(req: Request, key: string): string =
  return req.headers.getString(key)

proc getCookie*(req: Request, name: string): string =
  return req.cookies.getString(name.toLowerAscii, "")