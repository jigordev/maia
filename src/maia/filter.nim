import options, json, strutils
import ./http/request
import chronos/apps/http/httpserver

type
    Validator = proc(req: Request): bool {.gcsafe.}
    FilterError* = object of ValueError
    Filter* = object of RootObj
        validator: Validator = proc(req: Request): bool = true
        code*: HttpCode = Http400
        body*: string = $Http400

proc check*(f: Filter, req: Request): bool =
    try:
        f.validator(req)
    except Exception as exc:
        raise FilterError.newException(exc.msg)

proc custom*(f: Filter, validator: Validator): Filter =
    result = f
    result.validator = proc(req: Request): bool = 
        if validator(req):
            return f.validator(req)
        false

proc urlContains*(f: Filter, substring: string): Filter =
    f.custom(proc(req: Request): bool = substring in $req.uri)

proc urlExcludes*(f: Filter, substring: string): Filter =
    f.custom(proc(req: Request): bool = substring notin $req.uri)

proc isSecure*(f: Filter): Filter =
    f.custom(proc(req: Request): bool = req.secure)

proc notSecure*(f: Filter): Filter =
    f.custom(proc(req: Request): bool = not req.secure)

proc queryContains*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.query.contains(name))

proc queryExcludes*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = not req.query.contains(name))

proc queryEqTo*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.query.getString(name) == value)

proc queryNotEq*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.query.getString(name) != value)

proc argsContains*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.args.isSome and req.args.get().contains(name))

proc argsExcludes*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.args.isNone or not req.args.get().contains(name))

proc argEqTo*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.args.isSome and req.args.get().getString(name) == value)

proc argNotEq*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.args.isNone or req.args.get().getString(name) != value)

proc headersContains*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = not req.getHeader(name).isEmptyOrWhitespace)

proc headersExcludes*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.getHeader(name).isEmptyOrWhitespace)

proc headerEqTo*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.getHeader(name).toLowerAscii == value.toLowerAscii)

proc headerNotEq*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.getHeader(name).toLowerAscii != value.toLowerAscii)

proc cookiesContains*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = not req.getCookie(name).isEmptyOrWhitespace)

proc cookiesExcludes*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.getCookie(name).isEmptyOrWhitespace)

proc cookieEqTo*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.getCookie(name).toLowerAscii == value.toLowerAscii)

proc cookieNotEq*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.getCookie(name).toLowerAscii != value.toLowerAscii)

proc formContains*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.form.isSome and req.form.get().contains(name))

proc formExcludes*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.form.isNone or not req.form.get().contains(name))

proc formEqTo*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.form.isSome and req.form.get().getString(name) == value)

proc formNotEq*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.form.isNone or req.form.get().getString(name) != value)

proc jsonContains*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.json.isSome and req.json.get().hasKey(name))

proc jsonExcludes*(f: Filter, name: string): Filter =
    f.custom(proc(req: Request): bool = req.json.isNone or not req.json.get().hasKey(name))

proc jsonEqTo*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.json.isSome and req.json.get().getOrDefault(name).getStr == value)

proc jsonNotEq*(f: Filter, name, value: string): Filter =
    f.custom(proc(req: Request): bool = req.json.isNone or req.json.get().getOrDefault(name).getStr != value)