import strutils, re, options
import chronos/apps/http/httptable

proc pathToRegex*(expectedPath: string): Regex =
  var resultPath = expectedPath
  while resultPath.find(re":[a-zA-Z0-9]+") != -1:
    resultPath = resultPath.replace(re":[a-zA-Z0-9]+", "[a-zA-Z0-9]+")
  result = re("^" & resultPath & "$")

proc matchPath*(prefix: string, path: string): bool =
  let pattern = pathToRegex(prefix)
  path.match(pattern)

proc parseArgs*(expectedPath, actualPath: string): Option[HttpTable] =
  result = none(HttpTable)

  if ":" notin expectedPath:
    return

  var args = init(HttpTable)
  let expectedParts = expectedPath.split("/")
  let actualParts = actualPath.split("/")

  if expectedParts.len == actualParts.len:
    var count = 0
    for part in expectedParts:
      if part.startsWith(":"):
        let name = part[1..^1]
        args.add(name, actualParts[count])
      inc(count)
    result = some(args)
