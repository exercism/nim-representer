import std/[json, macros]
import mapping
import normalizations
import types

proc createRepresentation*(file: string): tuple[tree: NimNode, map: IdentMap] =
  var map: IdentMap
  let code = parseStmt(file)
  result = (tree: code.normalizeStmtList(map), map: map)

proc getTestableRepresentation*(contents: string, switch = false): SerializedRepresentation =
  let (tree, map) = createRepresentation(contents)
  result = (repr tree, $(if switch: %map.switchKeysValues else: %map))

