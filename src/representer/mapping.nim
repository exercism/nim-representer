import hashes, tables, strutils

type
  NormalizedIdent = string
  IdentMap* = OrderedTable[NormalizedIdent, string]

proc hash(x: NormalizedIdent): Hash {.used.} =
  !$(x[0].hash !& x[1..^1].hashIgnoreStyle)

proc `==`(a, b: NormalizedIdent): bool =
  a[0] == b[0] and cmpIgnoreStyle(a, b) == 0


when isMainModule:
  template setup: untyped {.dirty.} =
    var map: IdentMap

  block testInitialization:
    setup
    doAssert map.len == 0

  block insertIdentifier:
    setup
    map["x"] = "placeholder_1"
    map["y"] = "placeholder_2"
    doAssert map.len == 2
  
  block firstLetterCapital:
    setup
    map["x"] = "placeholder_0"
    map["X"] = "placeholder_1"
    doAssert map.len == 2

  block otherLetterCapitals:
    setup
    map["hello"] = "placeholder_1"
    map["hElLO"] = "placeholder_100"
    map["Hello"] = "placeholder_2"
    map["HELLo"] = "placeholder_200"
    doAssert map.len == 2