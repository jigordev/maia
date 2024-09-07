import chronos/apps/http/httpclient

proc testHttpClient*(address: TransportAddress, data: string): Future[tuple[success: bool, data: string]] {.async.} =
    var transp: StreamTransport
    try:
        transp = await connect(address)
        if len(data) > 0:
            let wres {.used.} = await transp.write(data)
        var rres = await transp.read()
        return (true, bytesToString(rres))
    except CatchableError as exc:
        return (false, exc.msg)
    finally:
        if not(isNil(transp)):
            await closeWait(transp)