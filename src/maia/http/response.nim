import nimja/parser
import chronos/apps/http/httpserver
import os, streams, json, options, cookies, md5
import ../[errors, utils]

const
  TEXT_HTML_MIME_TYPE = "text/html;charset=utf-8"
  JSON_MIME_TYPE = "application/json"
  MAX_FILE_SIZE_MB = 10 * 1024 * 1024
  CONTENT_TYPE = "Content-Type"
  CONTENT_DISPOSITION = "Content-Disposition"
  SET_COOKIE = "Set-Cookie"

type
  Response* = ref object
    nativeReq: HttpRequestRef
    nativeRes: HttpResponseRef
    status*: HttpCode
    body*: string
    headers*: HttpTable

proc newResponse*(req: HttpRequestRef): Response =
  new(result)
  result.nativeReq = req
  result.nativeRes = req.getResponse()
  result.status = Http200
  result.body = ""
  result.headers = init(HttpTable)

proc setStatus*(res: Response, code: HttpCode): Response =
  result = res
  result.status = code

proc setHeader*(res: Response, key, value: string): Response =
  result = res
  result.headers.set(key, value)

proc addHeader*(res: Response, key, value: string): Response =
  result = res
  result.headers.add(key, value)

proc hasHeader*(res: Response, key: string): bool =
  res.headers.contains(key)

proc getHeader*(res: Response, key: string, default: string = ""): string =
  res.headers.getString(key, default)

proc setCookie*(res: Response, key, value: string, domain = "",
    path = "", expires = "", noName = false, secure = false, httpOnly = false,
    maxAge: Option[int] = none(int), sameSite = SameSite.Default): Response =
  result = res
  var cookieStr = key & "=" & value
  if domain != "": cookieStr &= "; Domain=" & domain
  if path != "": cookieStr &= "; Path=" & path
  if expires != "": cookieStr &= "; Expires=" & expires
  if secure: cookieStr &= "; Secure"
  if httpOnly: cookieStr &= "; HttpOnly"
  if maxAge.isSome: cookieStr &= "; Max-Age=" & $maxAge.unsafeGet

  if sameSite != SameSite.Default:
    cookieStr &= "; SameSite=" & $sameSite
  discard res.setHeader("Set-Cookie", cookieStr)

proc clearCookies*(res: Response): Response =
  result = res
  res.nativeRes.setHeader(SET_COOKIE, "")

proc send*(res: Response, code: HttpCode): Future[Response] {.async.} =
  result = res
  discard res.nativeReq.respond(code, res.body, res.headers)

proc send*(res: Response, body: string): Future[Response] {.async.} =
  result = res
  if res.getHeader(CONTENT_TYPE).isEmptyOrWhitespace:
    discard res.setHeader(CONTENT_TYPE, TEXT_HTML_MIME_TYPE)
  discard res.nativeReq.respond(res.status, body, res.headers)

proc send*(res: Response, body: JsonNode): Future[Response] {.async.} =
  result = res
  discard res.setHeader(CONTENT_TYPE, JSON_MIME_TYPE)
    .nativeReq.respond(res.status, $body, res.headers)

proc redirect*(res: Response, location: string, code: HttpCode = Http302): Future[Response] {.async.} =
  result = res
  discard res.setStatus(code)
    .setHeader("Location", location)
    .nativeReq.respond(code, "", res.headers)

proc error*(res: Response, code: HttpCode, message: string = $code): Future[Response] {.async.} =
  result = res
  discard res.nativeReq.respond(code, errors.error(message, "0.1.0"), init(HttpTable))

proc prepare*(res: Response, streamType: HttpResponseStreamType = Chunked) {.async.} =
  await res.nativeRes.prepare(streamType)

proc write*(res: Response, data: string) {.async.} =
  await res.nativeRes.sendChunk(data)

proc event*(res: Response, name, data: string) {.async.} =
  await res.nativeRes.sendEvent(name, data)

proc finish*(res: Response) {.async.} =
  await res.nativeRes.finish()

proc sendFile*(res: Response, filename: string,
    downloadName: string = getFilename(filename), attachment: bool = true,
    maxAge: int = 0): Future[Response] {.async.} =
  if not fileExists(filename):
    return await res.error(Http404)

  let permissions = getFilePermissions(filename)
  if not (permissions.contains(fpGroupRead) or permissions.contains(fpOthersRead)):
    return await res.error(Http403)

  discard res.setHeader(CONTENT_TYPE, getFileMimeType(filename))

  if maxAge != 0:
    discard res.setHeader("Cache-Control", "public, max-age=" & $maxAge)

  if attachment:
    discard res.setHeader(CONTENT_DISPOSITION, "attachment; filename=\"" & downloadName & "\"")
  else:
    discard res.setHeader(CONTENT_DISPOSITION, "inline; filename=\"" & filename & "\"")

  if getFileSize(filename) < MAX_FILE_SIZE_MB: # Less than 10MB
    let content = readFile(filename)
    let hashed = md5.getMD5(content)
    if res.nativeReq.headers.getLastString("If-None-Match") == hashed:
      return await res.send(Http304)
    return await res.setHeader("ETag", hashed).send(content)
  else:
    await res.prepare()
    var fileStream = newFileStream(filename, fmRead)
    var line = ""

    try:
      while fileStream.readLine(line):
        await res.write(line)
    finally:
      fileStream.close()
      await res.finish()
      return res

template render*(res: Response, str: static string,
        context: untyped = nil): Future[Response] =
  result = res
  res.setHeader(CONTENT_TYPE, TEXT_HTML_MIME_TYPE)
    .send(tmpls(str, context))

template renderTemplate*(res: Response, filename: static string, context: untyped = nil): Future[Response] =
  result = res
  res.setHeader(CONTENT_TYPE, TEXT_HTML_MIME_TYPE)
    .send(tmplf(getScriptDir() / filename, context))
