import std/[sugar, tables]
import mapping

type
  Representation* = tuple
    tree: string
    map: IdentMap
  SerializedRepresentation* = tuple
    tree: string
    map: string

proc switchKeysValues*(map: IdentMap): OrderedTable[string, NormalizedIdent] =
  result = collect(initOrderedTable):
    for key, val in map.pairs:
      {val: key}
