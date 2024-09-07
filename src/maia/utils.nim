import os, mimetypes

proc getFilename*(filePath: string): string =
  let splited = splitFile(filePath)
  splited.name & splited.ext

proc getFileMimeType*(filePath: string): string =
  let m = newMimetypes()
  let ext = splitFile(filePath).ext
  m.getMimetype(ext)
