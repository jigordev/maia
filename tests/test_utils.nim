import unittest
import ../src/maia/utils

proc testUtils*() =
    suite "getFilename tests":
        test "getFilename with extension":
            check getFilename("data/file.txt") == "file.txt"

    suite "getFileMimeType tests":
        test "getFileMimeType for text file":
            check getFileMimeType("data/file.txt") == "text/plain"
