import htmlgen, strutils, sequtils

func debugException*(error: ref Exception): string =
    var fullStackTrace, formattedStackTrace: seq[string] = @[]
    var current = error
    while current != nil:
        fullStackTrace.add(current.getStackTrace())
        current = current.parent

    let mapped = fullStackTrace.mapIt(it.splitLines())
    var flatted: seq[string] = @[]
    for s in mapped:
        flatted.add(s)
    fullStackTrace = flatted

    for entry in fullStackTrace:
        formattedStackTrace.add(li(entry))

    return html(
      head(title("Maia Exception")),
      body(
        h1($error.name),
        p($error.name & ": " & error.msg),
        h2("Stack Trace:"),
        ul(formattedStackTrace.join(""))
        ),
    xmlns = "http://www.w3.org/1999/xhtml")

func defaultError*(): string =
    return html(head(title("Internal Server Error")),
        body(h1("Internal Server Error"),
            p("We're sorry, but something went wrong on our end. Please try again later. If the problem persists, contact support."),
        ),
    xmlns = "http://www.w3.org/1999/xhtml")

func error*(error: string, maiaVersion: string = ""): string =
    return html(head(title(error)),
       body(h1(error),
          "<hr/>",
          p("Maia Framework " & maiaVersion),
          style = "text-align: center;"
        ),
    xmlns = "http://www.w3.org/1999/xhtml")
