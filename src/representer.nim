# Create an normalized AST of a submission on exercism.io to provide feedback
import macros, strformat, sequtils, strutils, tables

proc normalizeStmtList(code: NimNode, map: var Table[string, string]): NimNode {.compileTime.}

proc getNormalization(node: NimNode, map: var Table[string, string]): NimNode {.compileTime.} =
  map.getOrDefault(node.strVal, node.strVal).ident

proc normalizeDefName(identDef: NimNode, map: var Table[string, string]): NimNode {.compileTime.} =
  map.mgetOrPut(identDef.strVal, fmt"placeholder_{map.len}").ident

proc addNewName(node: NimNode, map: var Table[string, string]): NimNode {.compileTime.} =
  if node.kind == nnkPostfix:
    node.unpackPostfix[0].normalizeDefName(map).postfix("*")
  else:
    node.normalizeDefName(map)

proc normalizeCall(call: NimNode, map: Table[string, string]): NimNode {.compileTime.} =
  call

proc normalizeValue(value: NimNode, map: var Table[string, string]): NimNode =
  case value.kind:
  of nnkLiterals: value
  of nnkIdent: value.normalizeDefName(map)
  of nnkCallKinds: value.normalizeCall(map)
  of nnkEmpty: value
  else:
    raise newException(ValueError, "dont know how to normalize type: " &
        $value.kind & " as a value")


proc normalizeIdentDef(def: NimNode, map: var Table[string, string]): NimNode {.compileTime.} =
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


proc normalizeRoutineDef(routineDef: NimNode, map: var Table[string,
    string]): NimNode {.compileTime.} =
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
  let returnType = routineDef[0]
  let identDefs = formalParams[1..^1].mapIt(it.normalizeIdentDef(map))
  routineDef.kind.newTree(
    routineDef[0].addNewName(map), # RoutineDef Name
    newEmptyNode(), # Term Rewriting macros and templates which are not supported
    newEmptyNode(), # TODO: Implement Generic Params
    nnkFormalParams.newTree(
      formalParams[0].getNormalization(map)
    ).add(identDefs),
    newEmptyNode(), # TODO: Implement pargma
    newEmptyNode(), # Empty, open for future use
    routineDef.last.normalizeStmtList(map)
  )

proc normalizeStmtList(code: NimNode, map: var Table[string,
    string]): NimNode {.compileTime.} =
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
    of nnkCommand, nnkCall, nnkInfix..nnkHiddenCallConv: # TODO: Tranform all syms
      statement.normalizeCall(map)
    else:
      statement
  normalizedTree

const tslug = "hello_world.nim"
const tinputDir = "/Users/ynf/Exercism/nim/hello-world/"
const path = tinputDir & tslug
var map {.compileTime.} = initTable[string, string](16)
let code {.compileTime.} = parseStmt path.staticRead
static:
  # echo code.treeRepr
  let code = normalizeStmtList(code, map)
  echo code.treeRepr
  echo map
