# Package

version       = "0.1.0"
author        = "alexgustafson"
description   = "A nim wrapper for the Clap Audio Plugin ABI"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"


task download_clap, "download clap":
  exec("curl -L https://github.com/free-audio/clap/archive/refs/heads/main.zip --output ./main.zip")
  exec("unzip ./main.zip")
  exec("rm -rf main.zip")
  exec("mv ./clap-main ./clap")


task generate_bindings, "generate bindings":
  exec("nim r scripts/generate_bindings.nim")


task debug, "debug simple plugin":
  exec "nim compile -g --debugger:native --app:lib --gc:orc -o:examples/my_plugin.clap examples/my_plugin.nim"


task build, "build simple plugin":
  exec "nim compile -g --app:lib --gc:orc -d:release -o:examples/my_plugin.clap examples/my_plugin.nim"

task build_hello, "build hello plugin":
  exec "nim compile -g --app:lib --gc:orc -d:release -o:examples/hello_clap.clap examples/hello_clap.nim"

task scratch, "scratch":
  exec "c2nim --dynlib --cdecl --out=scratch/plugin-template.nim scratch/plugin-template.c"
  exec "c2nim --dynlib --cdecl --out=scratch/scratch-c2nim.nim scratch/scratch-c2nim.c"
  # exec "nim compile cc --app:lib --gc:orc -o:scratch/scratch-nim2c.c scratch/scratch-nim2c.nim"