import std/[json, os, strformat, strutils]
import nimscripter
import representer/[mapping, types]
import docopt

const doc = """
Exercism nim representation normalizer.

Usage:
  representer --slug=<slug> --input-dir=<in-dir> [--output-dir=<out-dir>] [--print]

Options:
  -h --help                             Show this help message.
  -v, --version                         Display version.
  -p, --print                           Print the results.
  -s <slug>, --slug=<slug>              The exercise slug.
  -i <in-dir>, --input-dir=<in-dir>     The directory of the submission and exercise files.
  -o <out-dir>, --output-dir=<out-dir>  The directory to output to.
                                        If omitted, output will be written to stdout.
"""

proc getFileContents*(fileName: string): string = readFile fileName

func underSlug(s: string): string = s.replace('-', '_')

proc main() =
  let args = docopt(doc)
  let intr = loadScript(NimScriptPath("src/representer/loader.nims"))
  let (tree, map) = intr.invoke(
    getTestableRepresentation,
    getFileContents(&"""{args["--input-dir"]}/{($args["--slug"]).underSlug}.nim"""), true,
    returnType = SerializedRepresentation
  )
  if args["--output-dir"]:
    let outDir = $args["--output-dir"]
    writeFile outDir / "mapping.json", $map.parseJson
    writeFile outDir / "representation.txt", tree
  if not args["--output-dir"] or args["--print"]:
    echo &"{tree = }\n{map.parseJson.pretty = }"

when isMainModule:
  main()
