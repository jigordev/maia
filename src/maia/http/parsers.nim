import strutils, options, json
import chronos/apps/http/httpserver

type
  SameSite* {.pure.} = enum
    Default, None, Lax, Strict

proc parseCookie*(s: string): HttpTable =
  var i = 0
  while i < s.len:
    while i < s.len and (s[i] == ' ' or s[i] == '\t'): inc(i)
    var keystart = i
    while i < s.len and s[i] != '=': inc(i)
    var keyend = i
    if i >= s.len: break
    inc(i)
    var valstart = i
    while i < s.len and s[i] != ';' and s[i] != ',': inc(i)
    result.add(s[keystart .. keyend-1].strip, s[valstart .. i-1].strip)
    inc(i)

type
  FileUpload* = tuple[filename: string, buffer: seq[byte]]
  FileTable* = Table[string, FileUpload]
  RequestBody = tuple[data: seq[byte], form: Option[HttpTable], files: Option[FileTable], json: Option[JsonNode]]

proc read*(f: FileUpload): string =
  f.buffer.bytesToString

proc parseBody*(req: HttpRequestRef): Future[RequestBody] {.async.} =
  if req.meth notin PostMethods:
    return

  var
    data: seq[byte]
    form: HttpTable
    files: FileTable
    json: JsonNode

  if UrlencodedForm in req.requestFlags:
    let queryFlags =
      if QueryCommaSeparatedArray in req.connection.server.flags:
        {QueryParamsFlag.CommaSeparatedArray}
      else:
        {}
    data = await req.getBody()
    var strbody = data.bytesToString
    for key, value in queryParams(strbody, queryFlags):
      form.add(key, value)
    return (data, some(form), none(FileTable), none(JsonNode))
  elif MultipartForm in req.requestFlags:
    var hasForm, hasFile = false
    let mpreader = getMultipartReader(req).valueOr:
      raiseHttpProtocolError(Http400,
        "Unable to retrieve multipart form data, reason: " & $error)
    var runLoop = true
    while runLoop:
      var part: MultiPart
      try:
        part = await mpreader.readPart()
        var value = await part.getBody()
        data.add(value)
        var strvalue = value.bytesToString
        if part.filename.isEmptyOrWhitespace:
          hasForm = true
          form.add(part.name, strvalue)
        else:
          hasFile = true
          files[part.name] = (filename: part.filename, buffer: value)
        await part.closeWait()
      except MultipartEOMError:
        runLoop = false
      except HttpWriteError as exc:
        if not(part.isEmpty()):
          await part.closeWait()
        await mpreader.closeWait()
        raise exc
      except HttpProtocolError as exc:
        if not(part.isEmpty()):
          await part.closeWait()
        await mpreader.closeWait()
        raise exc
      except CancelledError as exc:
        if not(part.isEmpty()):
          await part.closeWait()
        await mpreader.closeWait()
        raise exc
    await mpreader.closeWait()
    return (data, if hasForm: some(form) else: none(HttpTable),
            if hasFile: some(files) else: none(FileTable), none(JsonNode))
  elif req.headers.getString("Content-Type").toLowerAscii == "application/json":
    try:
      data = await req.getBody()
      var jsonString = data.bytesToString  
      json = parseJson(jsonString)
      return (data, none(HttpTable), none(FileTable), some(json))
    except JsonParsingError:
      raiseHttpProtocolError(Http400, "Invalid json data")
  else:
    if HttpRequestFlags.BoundBody in req.requestFlags:
      if req.contentLength != 0:
        raiseHttpProtocolError(Http400, "Unsupported request body")
      return
    elif HttpRequestFlags.UnboundBody in req.requestFlags:
      raiseHttpProtocolError(Http400, "Unsupported request body")
  
