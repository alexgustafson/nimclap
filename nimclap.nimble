# Package

version       = "0.1.0"
author        = "Alex Gustafson"
description   = "A Clever Audio Plugin wrapper for nim"
license       = "MIT"
srcDir        = "src"
backend = "c"

# Dependencies

requires "nim >= 1.6.6"

from os import `/`, parentDir


task genbindings, "generate bindings":
  exec "nim r src"/"generate_bindings.nim"


task buildSimplePlugin, "build simple plugin":
  exec "nim r examples/simple_plugin.nim"