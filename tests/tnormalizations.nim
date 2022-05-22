import std/[json, strutils, unittest]
import nimscripter
import representer/types

let
  intr = loadScript(NimScriptPath "src/representer/loader.nims")

proc getRepresentation(t: string): tuple[tree: string, map: JsonNode] =
  let (tree, map) = intr.invoke(getTestableRepresentation, t, false, returnType = SerializedRepresentation)
  result = (tree, map.parseJson)

suite "End to end":
  test "Just one `let` statement":
    let (_, map) = getRepresentation """let x = 1"""
    check:
      map["x"].getStr == "placeholder_0"
      map.len == 1

  test "All features":
    let (_, map) = getRepresentation"""type
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
template testTemplate(code: untyped): untyped = discard"""

    check map.len == 11

  test "No params, return type or statements":
    let (tree, _) = getRepresentation """proc helloWorld* = discard"""

    check tree.strip == "proc placeholder_0*() =\n  discard".strip

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
    let (tree, _) = getRepresentation """import strutils, algorithm, macros as m

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

echo hELLOWORLD(name = 1, age = "how old am I?")"""
    check tree.strip == expected.string

suite "Test specific functionality":
  let expected = """import
  strformat

proc placeholder_1*(placeholder_0 = "you"): string =
  fmt"One for {placeholder_0}, one for me.""""
  test "fmt strings":
    let (tree, _) = getRepresentation """import strformat

proc twoFer*(name = "you"): string =
  fmt"One for {name}, one for me." """

    check tree.strip == expected.strip

  test "fmt string with `&`":
    let (tree, _) = getRepresentation """import strformat

proc twoFer*(name = "you"): string =
  &"One for {name}, one for me." """
    check expected.strip == tree.strip
