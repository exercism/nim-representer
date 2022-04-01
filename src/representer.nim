import macros, os, sequtils, strutils
import representer/[mapping, normalizations]

proc switchKeysValues*(map: IdentMap): OrderedTable[string, NormalizedIdent] =
  toSeq(map.pairs).mapIt((it[1], it[0])).toOrderedTable

proc createRepresentation*(fileName: string): tuple[tree: NimNode, map: IdentMap] =
  var map: IdentMap
  let code = parseStmt staticRead fileName
  result = (tree: code.normalizeStmtList(map), map: map)


const
  inDir {.strdefine.} = "/Users/ynf/Exercism/nim/hello-world/"
  outDir {.strdefine.} = ""
  slug {.strdefine.} = "hello-world"
  underSlug = slug.replace('-', '_')

when isMainModule:
  import json
  static:
    let
      (tree, map) = createRepresentation(inDir / underSlug & ".nim")
      finalMapping = map.switchKeysValues
    echo (%*{"map": finalMapping, "tree": tree.repr}).pretty
    when defined(outDir):
      writeFile(outDir / "representation.txt", tree.repr)
      writeFile(outDir / "mapping.json", $(%finalMapping))
