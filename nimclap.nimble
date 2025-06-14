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

task build_c_template, "Build the C plugin template as a CLAP plugin":
  exec "nim compile -g --app:lib -o:build/plugin-template.clap examples/plugin_template.nim"

task build_hello, "Build hello clap":
  exec "nim compile -g --app:lib -o:build/hello_clap.clap examples/hello_clap.nim"





