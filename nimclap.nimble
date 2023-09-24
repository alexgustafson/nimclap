# Package

version       = "0.1.0"
author        = "alexgustafson"
description   = "A nim wrapper for the Clap Audio Plugin ABI"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"



task generate_bindings, "generate bindings":
  exec("nim r scripts/generate_bindings.nim")


task debug, "debug simple plugin":
  exec "nim compile -g --debugger:native --app:lib --gc:orc -d:release -o:examples/my_plugin.clap examples/my_plugin.nim"

