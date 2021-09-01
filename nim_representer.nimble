# Package

version       = "0.1.0"
author        = "@exercism/nim"
description   = "A representer to normalize a submission on the `nim` track of exercism.io"
license       = "MIT"
srcDir        = "src"
bin           = @["representer"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.6.0", "macroutils == 1.2.0"
