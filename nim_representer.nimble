# Package

version       = "0.1.0"
author        = "Yoni Fihrer"
description   = "A representer to normalize submission on the `nim` track of exercism.io"
license       = "MIT"
srcDir        = "src"
bin           = @["representer"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.0.0", "docopt >= 0.6.8", "compiler >= 1.2.0"