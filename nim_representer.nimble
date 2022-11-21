# Package

version       = "0.1.0"
author        = "Yoni Fihrer"
description   = "A representer to normalize user-submitted code on the `nim` track of exercism.org"
license       = "MIT"
srcDir        = "src"
bin           = @["representer"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.6.6"
requires "nimscripter == 1.0.16"
requires "docopt == 0.6.8"
