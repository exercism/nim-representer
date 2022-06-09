import std/[json, macros]
import "."/[mapping, normalizations, types]

proc createRepresentation(contents: string): tuple[tree: NimNode, map: IdentMap] =
  var map: IdentMap
  let code = parseStmt(contents)
  result = (tree: code.normalizeStmtList(map), map: map)

proc getTestableRepresentation*(contents: string, switch = false): SerializedRepresentation =
  let (tree, map) = createRepresentation(contents)
  result = (repr tree, $(if switch: %map.switchKeysValues else: %map))
