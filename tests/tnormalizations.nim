import std/[macros, sequtils, strutils, unittest]
import representer/[mapping, normalizations]
import macroutils

macro setup(test, code: untyped): untyped =
  var map: IdentMap
  let
    tree = code.normalizeStmtList(map)
    tableConstr  = TableConstr(map.pairs.toSeq.map do (x: (NormalizedIdent, string)) -> auto:
      ExprColonExpr(
        DotExpr(
          Lit string x[0],
          Ident "NormalizedIdent"
        ),
        Lit x[1]
      )
    )
    tableInit =
      if tableConstr.len != 0:
        newDotExpr(
          tableConstr,
          "toOrderedTable".ident
        )
      else:
        newEmptyNode()
  let
    treeIdent = ident "tree"
    mapIdent = ident "map"

  result = superQuote do:
    let `treeIdent` {.used.} = `repr(tree)`
    var `mapIdent` {.used.} = `tableInit`
    check(`test`)

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
