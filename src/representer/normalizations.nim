## Create an normalized AST of a submission on exercism.io to provide feedback
import algorithm, macros, strformat, sequtils, strutils, std/with
import mapping

proc normalizeStmtList*(code: NimNode, map: var IdentMap): NimNode
proc normalizeValue(value: NimNode, map: var IdentMap): NimNode

proc getNormalization(node: NimNode, map: var IdentMap): NimNode =
  map.getOrDefault(node.strVal.NormalizedIdent, node.strVal).ident

proc normalizeDefName(identDef: NimNode, map: var IdentMap): NimNode =
  map.mgetOrPut(identDef.strVal.NormalizedIdent, fmt"placeholder_{map.len}").ident

proc addNewName(node: NimNode, map: var IdentMap): NimNode =
  case node.kind:
  of nnkPostfix:
    node.unpackPostfix[0].normalizeDefName(map).postfix("*")
  of nnkAccQuoted:
    nnkAccQuoted.newTree(node.name.normalizeDefName(map))
  else:
    node.normalizeDefName(map)

proc normalizeEqExpr(eqExpr: NimNode, map: var IdentMap): NimNode =
  eqExpr.expectKind nnkExprEqExpr
  nnkExprEqExpr.newTree(eqExpr[0].normalizeValue(map), eqExpr[1].normalizeValue(map))

proc normalizeCall(call: NimNode, map: var IdentMap): NimNode =
  result = newCall(
    call[0].normalizeValue(map),
  )
  for param in call[1..^1]:
    result.add case param.kind:
      of nnkExprEqExpr:
        nnkExprEqExpr.newTree(param[0].normalizeValue(map), param[1].normalizeValue(map))
      else:
        param.normalizeValue(map)

proc normalizeValue(value: NimNode, map: var IdentMap): NimNode =
  case value.kind:
  of nnkLiterals: value
  of nnkIdent: value.getNormalization(map)
  of nnkCallKinds: value.normalizeCall(map)
  of nnkEmpty: value
  of nnkStmtList: value.normalizeStmtList(map)
  of nnkDotExpr: newDotExpr(value[0].normalizeValue(map), value[1].normalizeValue(map))
  of nnkPar: value[0].normalizeValue(map)
  else:
    raise newException(ValueError, "dont know how to normalize " & value.repr & " with type: " &
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
  result = newIdentDefs(name, defType, default)

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
  result = routineDef.kind.newTree(
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
  result = nnkStmtList.newTree

  for index, statement in code:
    result.add case statement.kind:
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
    of nnkCallKinds:
      statement.normalizeCall(map)
    of nnkImportStmt, nnkFromStmt, nnkImportExceptStmt:
      statement.normalizeImportExport(map)
    of nnkDiscardStmt:
      nnkDiscardStmt.newNimNode.add statement[0].normalizeValue(map)
    of nnkIdent, nnkDotExpr:
      statement.normalizeValue(map)
    else:
      statement
