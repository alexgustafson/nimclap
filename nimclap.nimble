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
  when defined(windows):
    exec "nim compile -g --app:lib --passL:\"-static-libgcc -static-libstdc++\" -o:build/hello_clap.clap examples/hello_clap.nim"
  elif defined(macosx):
    exec "nim compile -g --app:lib -o:build/hello_clap.clap examples/hello_clap.nim"
  else:  # Linux and other Unix-like systems
    exec "nim compile -g --app:lib --passL:\"-static-libgcc\" -o:build/hello_clap.clap examples/hello_clap.nim"

task build_clap_loader, "Build the CLAP plugin loader test tool":
  when defined(windows):
    exec "gcc -o tests/clap_loader.exe tests/clap_loader.c"
  else:
    exec "gcc -o tests/clap_loader tests/clap_loader.c -ldl"







