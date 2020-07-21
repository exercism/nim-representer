import macros, os, sequtils, strutils
import representer/[mapping, normalizations]


proc createRepresentation*(fileName: string): tuple[tree: NimNode, map: IdentMap] =
  var map: IdentMap
  let code = parseStmt fileName.staticRead
  result = (tree: code.normalizeStmtList(map), map: map)


when isMainModule:
  import json
  static:
    const path {.strdefine.} = "../../Exercism/nim/two-fer/two_fer.nim" ##\
    ## The path to the file to create representation for
    ## Can be invoked with -d:path=<PATH-TO-FILE>
    let (tree, map) = createRepresentation path
    echo (%*{"map": map, "tree": tree.repr}).pretty
