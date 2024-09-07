import unittest
import ../src/maia
import ../src/maia/errors

proc testErrors*() =
    suite "debugException tests":  
        test "Simple exception":
            let error = newException(ValueError, "Test simple exception")
            let result = debugException(error)
            check result.contains("<h1>ValueError</h1>")
            check result.contains("<p>ValueError: Test simple exception</p>")
            check result.contains("<h2>Stack Trace:</h2>")

        test "Stack trace exception":
            try:
                raise newException(IOError, "I/O error")
            except IOError as exc:
                let result = debugException(exc)
                check result.contains("<h1>IOError</h1>")
                check result.contains("<p>IOError: I/O error</p>")
                check result.contains("<h2>Stack Trace:</h2>")
                check result.contains("<li>")

    suite "error test":
        test "Simple error message":
            let errorMsg = "Generic error"
            let result = error(errorMsg)
            check result.contains("<h1>Generic error</h1>")
            check result.contains("<hr/>")
            check result.contains("<p>Maia Framework ")

        test "Error with version":
            let errorMsg = "Error with version"
            let maiaVer = "v1.0.0"
            let result = error(errorMsg, maiaVer)
            check result.contains("<h1>Error with version</h1>")
            check result.contains("<p>Maia Framework v1.0.0</p>")
            check result.contains("style=\"text-align: center;\"")

    suite "defaultError test":
        test "Default error message test":
            let errorTitle = "Internal Server Error"
            let errorMsg = "We're sorry, but something went wrong on our end. Please try again later. If the problem persists, contact support."
            let result = defaultError()
            check result.contains(errorTitle)
            check result.contains(errorMsg)
