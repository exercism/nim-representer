import representer/[mapping, normalizations]
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
proc placeholder_2*() =
  echo("testing stdout")

placeholder_2()
proc placeholder_5*(placeholder_3: int; placeholder_4 = "seventeen"): string =
  let placeholder_6 = `-`(placeholder_3, placeholder_0)
  let placeholder_7 = `&`(placeholder_1, placeholder_4)
  let placeholder_8 = `&`(`$`(placeholder_6), placeholder_7)
  placeholder_8

echo(placeholder_0.placeholder_5)
echo(placeholder_5(placeholder_3 = 1, placeholder_4 = "how old am I?"))"""
    setup(tree.strip == expected.strip):
      import strutils, algorithm, macros as m

      let
        x = 1
        y = ($x).strip.replace("\n", $x)

      proc testStdout*() =
        echo "testing stdout"

      testStdout()

      proc helloWorld*(name: int, age = "seventeen"): string =
        let years = name - x
        let fullName = y & age
        let id = $yEARs & fuLLNamE
        id

      echo x.helloWorld

      echo hELLOWORLD(name = 1, age = "how old am I?")

suite "Test specific functionality":
  let expected = """import
  strformat

proc placeholder_1*(placeholder_0 = "you"): string =
  fmt"One for {placeholder_0}, one for me.""""
  test "fmt strings":
    setup(tree.strip == expected.strip):
      import strformat

      proc twoFer*(name = "you"): string =
        fmt"One for {name}, one for me."

  test "fmt string with `&`":
    setup(tree.strip == expected.strip):
      import strformat

      proc twoFer*(name = "you"): string =
        &"One for {name}, one for me."

suite "Test specific functionality":
  let expected = """import
  strformat

proc placeholder_1*(placeholder_0 = "you"): string =
  fmt"One for {placeholder_0}, one for me.""""
  test "fmt strings":
    setup(tree.strip == expected.strip):
      import strformat

      proc twoFer*(name = "you"): string =
        fmt"One for {name}, one for me."

  test "fmt string with `&`":
    setup(tree.strip == expected.strip):
      import strformat

      proc twoFer*(name = "you"): string =
        &"One for {name}, one for me."
