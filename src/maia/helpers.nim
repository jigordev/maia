import asyncdispatch

template runAsync*(prc: untyped): untyped =
  waitFor prc