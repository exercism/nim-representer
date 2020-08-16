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

proc constructFmtStr(ast: NimNode, map: var IdentMap): string =
  with result:
    add "{"
    add ast[2].normalizeValue(map).repr
    add if ($ast[3]).len != 0: ":" & $ast[3] else: ""
    add "}"


proc normalizeCall(call: NimNode, map: var IdentMap): NimNode =
  result =
    if call.kind != nnkInfix and (call[0] == "fmt".ident or call[0] == "&".ident):
      let fmtAst = getAst(fmt(call[1]))
      let strToFmt = fmtAst[1..^2].mapIt(
        if $it[0][0] == "add":
          $it[2]
        else:
          constructFmtStr it, map
      ).join

      nnkCallStrLit.newTree(
        "fmt".ident,
        newLit strToFmt
      )

    else:
      newCall(call[0].normalizeValue(map), call[1..^1].mapIt(
        if it.kind == nnkExprEqExpr:
          it.normalizeEqExpr(map)
        else:
          it.normalizeValue(map))
      )

proc normalizeConditionalBranch(branch: NimNode, map: var IdentMap): NimNode =
  result = branch.kind.newNimNode
  if branch.kind in {nnkElifBranch, nnkElifExpr}:
    result.add branch[0].normalizeValue(map)
  result.add branch[^1].normalizeStmtList(map)

proc normalizeCond(ifStmt: NimNode, map: var IdentMap): NimNode =
  ifStmt.expectKind {nnkIfExpr, nnkIfStmt, nnkWhenStmt}
  result = ifStmt.kind.newTree(
    ifStmt.mapIt(it.normalizeConditionalBranch(map))
  )

proc normalizeCaseBranch(caseBranch: NimNode, map: var IdentMap): NimNode =
  caseBranch.expectKind {nnkOfBranch, nnkElifBranch, nnkElse}
  case caseBranch.kind:
  of nnkOfBranch:
    caseBranch.kind.newTree(
      caseBranch[0..^2].mapIt(it.normalizeValue(map))
    ).add caseBranch[^1].normalizeStmtList(map)
  else:
    caseBranch.normalizeConditionalBranch(map)

proc normalizeCase(caseStmt: NimNode, map: var IdentMap): NimNode =
  caseStmt.expectKind nnkCaseStmt
  result = nnkCaseStmt.newTree(
    caseStmt[0].normalizeValue(map)
  ).add caseStmt[1..^1].mapIt(it.normalizeCaseBranch(map))

proc normalizeValue(value: NimNode, map: var IdentMap): NimNode =
  case value.kind:
  of nnkLiterals: value
  of nnkIdent: value.getNormalization(map)
  of nnkCallKinds: value.normalizeCall(map)
  of nnkEmpty: value
  of nnkStmtList: value.normalizeStmtList(map)
  of nnkDotExpr: newDotExpr(value[0].normalizeValue(map), value[1].normalizeValue(map))
  of nnkPar: value[0].normalizeValue(map)
  of nnkIfExpr, nnkWhenStmt: value.normalizeCond(map)
  of nnkCaseStmt: value.normalizeCase(map)
  else:
    error "dont know how to normalize " & value.repr & " with type: " &
        $value.kind & " as a value"
    newEmptyNode()


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
    error $importStmt & "is not a valid import or export stmt"
    newEmptyNode()

proc normalizeLoop(loopStmt: NimNode, map: var IdentMap): NimNode =
  loopStmt.expectKind {nnkForStmt, nnkWhileStmt}
  result = newNimNode loopStmt.kind
  if loopStmt.kind == nnkForStmt:
    result.add loopStmt[0..^3].mapIt(it.normalizeDefName(map))
  result.add loopStmt[^2].normalizeValue(map)
  result.add loopStmt[^1].normalizeStmtList(map)

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
    of nnkIdent, nnkDotExpr:
      statement.normalizeValue(map)
    of nnkBreakStmt, nnkDiscardStmt, nnkReturnStmt, nnkYieldStmt: # TODO: mixin and bind statements
      statement.kind.newNimNode.add statement[0].normalizeValue(map)
    of nnkIfStmt, nnkIfExpr, nnkWhenStmt:
      statement.normalizeCond(map)
    of nnkCaseStmt:
      statement.normalizeCase(map)
    of nnkWhileStmt, nnkForStmt:
      statement.normalizeLoop(map)
    else:
      statement
