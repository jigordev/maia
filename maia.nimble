# Package

version       = "0.1.0"
author        = "jigordev"
description   = "A lightweight and efficient web framework for the Nim programming language."
license       = "MIT"
srcDir        = "src"

skipDirs = @["tests"]

# Dependencies

requires "nim >= 2.0.4"
requires "chronos == 4.0.2"
requires "nimja == 0.8.7"


task test, "Runs the test suite.":
  exec "nim c -d:debug -r tests/tester"