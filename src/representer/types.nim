import std/[sequtils, tables]
import mapping

type
  Representation* = tuple
    tree: string
    map: IdentMap
  SerializedRepresentation* = tuple
    tree: string
    map: string

proc switchKeysValues*(map: IdentMap): OrderedTable[string, NormalizedIdent] =
  toSeq(map.pairs).mapIt((it[1], it[0])).toOrderedTable

