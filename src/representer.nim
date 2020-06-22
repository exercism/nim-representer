# Create an normalized AST of a submission on exercism.io to provide feedback
import macros, strformat, sequtils, strutils, tables
when isMainModule:
  import json

proc normalizeStmtList*(code: NimNode, map: var OrderedTable[string, string]): NimNode
proc normalizeValue(value: NimNode, map: var OrderedTable[string, string]): NimNode

proc getNormalization(node: NimNode, map: var OrderedTable[string, string]): NimNode =
  map.getOrDefault(node.strVal, node.strVal).ident

proc normalizeDefName(identDef: NimNode, map: var OrderedTable[string, string]): NimNode =
  map.mgetOrPut(identDef.strVal, fmt"placeholder_{map.len}").ident

proc addNewName(node: NimNode, map: var OrderedTable[string, string]): NimNode =
  case node.kind:
  of nnkPostfix:
    node.unpackPostfix[0].normalizeDefName(map).postfix("*")
  of nnkAccQuoted:
    nnkAccQuoted.newTree(node.name.normalizeDefName(map))
  else:
    node.normalizeDefName(map)

proc normalizeCall(call: NimNode, map: var OrderedTable[string, string]): NimNode =
  result = newCall(
    call[0].getNormalization(map),
  )
  for param in call[1..^1]:
    result.add case param.kind:
      of nnkExprEqExpr:
        param[1].normalizeValue(map)
      else:
        param.normalizeValue(map)
        


proc normalizeValue(value: NimNode, map: var OrderedTable[string, string]): NimNode =
  case value.kind:
  of nnkLiterals: value
  of nnkIdent: value.normalizeDefName(map)
  of nnkCallKinds: value.normalizeCall(map)
  of nnkEmpty: value
  of nnkStmtList: value.normalizeStmtList(map) # for macros and templates
  else:
    raise newException(ValueError, "dont know how to normalize type: " &
        $value.kind & " as a value")


proc normalizeIdentDef(def: NimNode, map: var OrderedTable[string, string]): NimNode =
  var (name, defType, default) = (def[0], def[1], def[2])
  # TODO: multiple identifiers
  name = name.normalizeDefName(map)

  if defType.kind != nnkEmpty:
    defType = defType.getNormalization(map)

  if default.kind notin  nnkLiterals:
    default = default.normalizeValue(map)
  # TODO: deal with complex types (distinct, obj, tuples)
  # TODO: generic parameters
  newIdentDefs(name, defType, default)

proc normalizeRoutineDef(routineDef: NimNode, map: var OrderedTable[string, string]): NimNode =
  ## RoutingDef Tree:
    ##    Ident | Postfix(*, Ident) # proc name
    ##    Empty # Related to Term rewriting macros which are not supported
    ##    Empty | GenericParams
    ##      IdentDefs
    ##        Ident
    ##        Type
    ##    FormalParams
    ##      empty | returntype
    ##      @[IdentDefs]
    ##        idents | @[ident, ident]
    ##        ident -> type
    ##        empty | default
    ##    Pragmas
    ##    Empty
    ##    StmtList # meat and potatoes
  let formalParams = routineDef[3]
  let returnType = formalParams[0]
  let identDefs = formalParams[1..^1].mapIt(it.normalizeIdentDef(map))
  routineDef.kind.newTree(
    routineDef[0].addNewName(map), # RoutineDef Name
    newEmptyNode(), # Term Rewriting macros and templates which are not supported
    newEmptyNode(), # TODO: Implement Generic Params
    nnkFormalParams.newTree(
      returnType.getNormalization(map)
    ).add(identDefs),
    newEmptyNode(), # TODO: Implement pargma
    newEmptyNode(), # Empty, open for future use
    routineDef.last.normalizeStmtList(map)
  )

proc normalizeStmtList*(code: NimNode, map: var OrderedTable[string, string]): NimNode =
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
    else:
      statement
  normalizedTree

proc createRepresentation*(fileName: string): (NimNode, OrderedTable[string, string]) =
  var map = initOrderedTable[string, string](16)
  let code = parseStmt fileName.staticRead
  (code.normalizeStmtList(map), map)

when defined(server):
  static:
    let (tree, map)  = createRepresentation "../../representation-web-viewer/public/code.nim"
    echo (%*{"map": map, "tree":tree.repr}).pretty
else:
  when isMainModule:
    static:
      let (tree, map) = createRepresentation "../../Exercism/nim/hello-world/hello_world.nim"
      echo tree.repr, '\n', '\n', (%*map).pretty
