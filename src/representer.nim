import std/[json, os, parseopt, strformat, strutils]
import nimscripter
import representer/[mapping, types]

type CliArgs = object
  slug: string
  inputDir: string
  outputDir: string
  printResult: bool

const usage = """
Usage:
  representer --slug=<slug> --input-dir=<in-dir> [--output-dir=<out-dir>] [--print]
""".dedent

proc getFileContents(fileName: string): string = readFile fileName

func kebabToSnakeCase(s: string): string = s.replace('-', '_')

proc parseArgs(params: seq[string]): CliArgs =
  var parser = initOptParser(params)

  while true:
    parser.next()
    case parser.kind
    of cmdLongOption, cmdShortOption:
      case parser.key
      of "slug", "s":
        result.slug = parser.val
      of "input-dir", "i":
        result.inputDir = parser.val
      of "output-dir", "o":
        result.outputDir = parser.val
      of "print", "p":
        result.printResult = true
      of "help", "h":
        echo usage
        quit QuitSuccess
      of "version", "v":
        echo "nim_representer 0.1.0"
        quit QuitSuccess
      else:
        quit("Unknown option: --" & parser.key, QuitFailure)
    of cmdArgument:
      quit("Unexpected argument: " & parser.key, QuitFailure)
    of cmdEnd:
      break

  if result.slug.len == 0:
    quit("Missing required option: --slug\n\n" & usage, QuitFailure)
  if result.inputDir.len == 0:
    quit("Missing required option: --input-dir\n\n" & usage, QuitFailure)

proc main() =
  let args = parseArgs(commandLineParams())
  let intr = loadScript(NimScriptPath("src/representer/loader.nims"))
  let (tree, map) = intr.invoke(
    getTestableRepresentation,
    getFileContents(args.inputDir / kebabToSnakeCase(args.slug) & ".nim"), true,
    returnType = SerializedRepresentation
  )
  if args.outputDir.len > 0:
    let outDir = args.outputDir
    writeFile outDir / "mapping.json", $map.parseJson
    writeFile outDir / "representation.txt", tree
  if args.outputDir.len == 0 or args.printResult:
    echo &"{tree = }\n{map.parseJson.pretty = }"

when isMainModule:
  main()
