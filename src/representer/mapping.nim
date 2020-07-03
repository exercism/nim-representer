import hashes, json, tables, strutils
export tables

type
  NormalizedIdent* = distinct string
  IdentMap* = OrderedTable[NormalizedIdent, string]

proc `[]`[I: Ordinal | BackwardsIndex](s: NormalizedIdent, i: I): char = s.string[i]
proc `[]`[T: Ordinal, U: Ordinal](s: NormalizedIdent, x: HSlice[T, U]): string = s.string[x]

proc hash*(x: NormalizedIdent): Hash {.used.} =
  !$(x[0].hash !& x[1..^1].hashIgnoreStyle)

proc `==`*(a, b: NormalizedIdent): bool =
  a[0] == b[0] and cmpIgnoreStyle(a.string, b.string) == 0

proc `%`*(ident: NormalizedIdent): JsonNode {.borrow.}
proc `$`*(ident: NormalizedIdent): string {.borrow.}
