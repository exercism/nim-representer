import macros, os, sequtils, strutils
import representer/[mapping, normalizations]

proc switchKeysValues*(map: IdentMap): OrderedTable[string, NormalizedIdent] =
  toSeq(map.pairs).mapIt((it[1], it[0])).toOrderedTable

proc createRepresentation*(fileName: string): tuple[tree: NimNode, map: IdentMap] =
  var map: IdentMap
  let code = parseStmt fileName.staticRead
  result = (tree: code.normalizeStmtList(map), map: map)


const inDir {.strdefine.} = ""
const outDir {.strdefine.} = ""
const slug {.strdefine.} = ""
const underSlug = slug.replace('-', '_')

when isMainModule:
  import json
  static:
    let (tree, map) = createRepresentation(inDdir / underSlug & ".nim")
    let finalMapping = map.switchKeysValues
    echo (%*{"map": finalMapping, "tree": tree.repr}).pretty
    when defined(dir):
      writeFile(outDir / "representation.txt", tree.repr)
      writeFile(outDdir / "mapping.json", $(%finalMapping))
