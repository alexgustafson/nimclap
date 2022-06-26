# Package

version       = "0.1.0"
author        = "Alex Gustafson"
description   = "A Nim wrapper around then Clever Audio Plugin library"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.6"

from os import `/`, parentDir


task genbindings, "generate bindings":
  exec "nim r src"/"generate_bindings.nim"


task buildSimplePlugin, "build simple plugin":
  exec "nim examples/simple_plugin.nim"