import representer
import macros, sequtils, strutils, unittest


macro setup(test, code: untyped): untyped =
  var map: IdentMap
  let tree = code.normalizeStmtList(map)
  let tableConstr = nnkTableConstr.newTree.add(toSeq(map.pairs).mapIt(
    nnkExprColonExpr.newTree(
        newDotExpr(it[0].string.newStrLitNode, "NormalizedIdent".ident),
        it[1].newStrLitNode
    )
  ))

  let tableInit = 
    if tableConstr.len != 0:
      newDotExpr(
        tableConstr,
        "toOrderedTable".ident
      )
    else:
      newEmptyNode()

  newStmtList(
    nnkLetSection.newTree(
      nnkIdentDefs.newTree(
        nnkPragmaExpr.newTree(
          ident "tree",
          nnkPragma.newTree(ident "used")
        ),
        newEmptyNode(),
        newLit tree.repr
      ),
    ),
    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        nnkPragmaExpr.newTree(
          ident "map",
          nnkPragma.newTree(ident "used")
        ),
        "IdentMap".ident,
        tableInit
      )
    ),

    newCall("check", test)
  )

suite "End to end":
  test "Just one `let` statement":
    setup(map["x".NormalizedIdent] == "placeholder_0" and map.len == 1):
      let x = 1

  test "All features":
    
    setup(map.len == 11):
      type
        Dollar = distinct int

      proc testProc(name: string = "", hello: int) =

        discard name & $hello

      let
        x = 1
        y = 2
        z = y + x

      var
        dollar: Dollar
      
      const
        euro = 100.Dollar
      
      testProc(name = $x, hello = y)
      testproC x

      macro testMacro(code: untyped): untyped = discard
      template testTemplate(code: untyped): untyped = discard
  test "No params, return type or statements":
    setup(tree.strip == "proc placeholder_0*() =\n  discard".strip):
      proc helloWorld* = discard
  test "All the things":
    const expected = """import
  algorithm, macros as m, strutils

let
  placeholder_0 = 1
  placeholder_1 = `$`(placeholder_0).strip.replace("\n", `$`(placeholder_0))
proc placeholder_4*(placeholder_2: int; placeholder_3: string): string =
  let placeholder_5 = `-`(placeholder_2, placeholder_0)
  let placeholder_6 = `&`(placeholder_1, placeholder_3)
  `&`(`$`(placeholder_5), placeholder_6)

placeholder_4(placeholder_2 = 1, placeholder_3 = "how old am I?")"""
    setup(tree.strip == expected.strip):
      import strutils, algorithm, macros as m

      let
        x = 1
        y = ($x).strip.replace("\n", $x)

      proc helloWorld*(name: int, age: string): string =
        let years = name - x
        let fullName = y & age
        $yEARs & fuLLNamE
      
      hELLOWORLD(name = 1, age = "how old am I?")
