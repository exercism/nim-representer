## Create an normalized AST of a submission on exercism.io to provide feedback
import algorithm, macros, strformat, sequtils, strutils, tables
import representer/mapping
when isMainModule:
  import json

export IdentMap

proc normalizeStmtList*(code: NimNode, map: var IdentMap): NimNode
proc normalizeValue(value: NimNode, map: var IdentMap): NimNode

proc getNormalization(node: NimNode, map: var IdentMap): NimNode =
  map.getOrDefault(node.strVal, node.strVal).ident

proc normalizeDefName(identDef: NimNode, map: var IdentMap): NimNode =
  map.mgetOrPut(identDef.strVal, fmt"placeholder_{map.len}").ident

proc addNewName(node: NimNode, map: var IdentMap): NimNode =
  case node.kind:
  of nnkPostfix:
    node.unpackPostfix[0].normalizeDefName(map).postfix("*")
  of nnkAccQuoted:
    nnkAccQuoted.newTree(node.name.normalizeDefName(map))
  else:
    node.normalizeDefName(map)

proc normalizeCall(call: NimNode, map: var IdentMap): NimNode =
  result = newCall(
    call[0].normalizeValue(map),
  )
  for param in call[1..^1]:
    result.add case param.kind:
      of nnkExprEqExpr:
        param[1].normalizeValue(map)
      else:
        param.normalizeValue(map)

proc normalizeValue(value: NimNode, map: var IdentMap): NimNode =
  case value.kind:
  of nnkLiterals: value
  of nnkIdent: value.normalizeDefName(map)
  of nnkCallKinds: value.normalizeCall(map)
  of nnkEmpty: value
  of nnkStmtList: value.normalizeStmtList(map)
  of nnkDotExpr: newDotExpr(value[0], value[1])
  else:
    raise newException(ValueError, "dont know how to normalize type: " &
        $value.kind & " as a value")


proc normalizeIdentDef(def: NimNode, map: var IdentMap): NimNode =
  var (name, defType, default) = (def[0], def[1], def[2])
  # TODO: multiple identifiers
  name = name.normalizeDefName(map)

  if defType.kind != nnkEmpty:
    defType = defType.getNormalization(map)

  if default.kind notin nnkLiterals:
    default = default.normalizeValue(map)
  # TODO: generic parameters
  newIdentDefs(name, defType, default)

proc normalizeRoutineDef(routineDef: NimNode, map: var IdentMap): NimNode =
  ## RoutineDef Tree:
  ##   Ident | Postfix(\*, Ident) (proc name)
  ##   Empty # Related to Term rewriting macros which are not supported
  ##   Empty | GenericParams
  ##     IdentDefs
  ##       Ident
  ##       Type
  ##   FormalParams
  ##     empty | returntype
  ##     @[IdentDefs] =
  ##       idents | @[ident, ident]
  ##       ident -> type
  ##       empty | default
  ##   Pragmas
  ##   Empty
  ##   StmtList # meat and potatoes
  let formalParams = routineDef[3]
  let returnType = formalParams[0]
  let identDefs = formalParams[1..^1].mapIt(it.normalizeIdentDef(map))
  routineDef.kind.newTree(
    routineDef[0].addNewName(map), # RoutineDef Name
    newEmptyNode(), # Term Rewriting macros and templates which are not supported
    newEmptyNode(), # TODO: Implement Generic Params
    nnkFormalParams.newTree(
      returnType.normalizeValue(map)
    ).add(identDefs),
    newEmptyNode(), # TODO: Implement pragma
    newEmptyNode(), # Empty, open for future use
    routineDef.last.normalizeStmtList(map)
  )

proc normalizeImportExport(importStmt: NimNode, map: IdentMap): NimNode =
  case importStmt.kind:
  of nnkImportExceptStmt, nnkFromStmt, nnkExportExceptStmt:
    importStmt.kind.newTree(importStmt[0]).add importStmt[1..^1].sortedByIt(it.strVal)
  of nnkImportStmt, nnkExportStmt:
    importStmt.kind.newTree(importStmt[0..^1].sortedByIt(if it.kind == nnkInfix: it.unpackInfix.left.strVal else: it.strVal)) # TODO: implemement normalizations of `import macros as m`
  else:
    raise newException(ValueError, $importStmt & "is not a valid import or export stmt")

proc normalizeStmtList*(code: NimNode, map: var IdentMap): NimNode =
  code.expectKind nnkStmtList
  var normalizedTree = nnkStmtList.newTree

  for index, statement in code:
    normalizedTree.add case statement.kind:
    of nnkCommentStmt: continue
    of nnkVarSection..nnkConstSection:
      var newDefSection = statement.kind.newTree()
      for def in statement:
        newDefSection.add def.normalizeIdentDef(map)
      newDefSection
    of nnkTypeSection: # TODO: Implement type normalizaation
      statement
    of RoutineNodes - {nnkLambda, nnkDo}: # We aren't supporting `do:` as of yet
      statement.normalizeRoutineDef(map)
    of nnkCallKinds: # TODO: nnkDotExprs? nnkCallStrLit?
      statement.normalizeCall(map)
    of nnkImportStmt, nnkFromStmt, nnkImportExceptStmt:
      statement.normalizeImportExport(map)
    of nnkDiscardStmt:
      nnkDiscardStmt.newNimNode.add statement[0].normalizeValue(map)
    else:
      statement

  normalizedTree

proc createRepresentation*(fileName: string): (NimNode, IdentMap) =
  var map: IdentMap
  let code = parseStmt fileName.staticRead
  (code.normalizeStmtList(map), map)

when isMainModule:
  static:
    const path {.strdefine.} = "../../Exercism/nim/two-fer/two_fer.nim" ##\
    ## The path to the file to create representation for
    ## Can be invoked with -d:path=<PATH-TO-FILE>
    let (tree, map) = createRepresentation path
    echo (%*{"map": map, "tree" : tree.repr}).pretty
