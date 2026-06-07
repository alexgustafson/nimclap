# Package

version       = "0.1.0"
author        = "alexgustafson"
description   = "A native Nim implementation of the CLAP audio plugin ABI"
license       = "MIT"
srcDir        = "src"


# Dependencies
requires "nim >= 2.0.0"

# --- CLAP ABI tracking -------------------------------------------------------
# The Nim bindings under src/nimclap/clap are hand-maintained. The upstream
# CLAP C headers live in the `clap/` git submodule and are pinned to a reviewed
# commit recorded in tests/clap_abi.baseline. These tasks help keep the
# bindings in sync. See tests/abi_tracker.nim for details.

task check_abi, "Report CLAP header changes since the last reviewed baseline":
  exec("nim r --hints:off tests/abi_tracker.nim check")

task update_clap, "Pull the latest CLAP headers into the submodule, then report drift":
  exec("git submodule update --remote clap")
  exec("nim r --hints:off tests/abi_tracker.nim check")

task bless_abi, "Record the current CLAP submodule commit as the reviewed baseline":
  exec("nim r --hints:off tests/abi_tracker.nim bless")

task test, "Compile the bindings and gate on CLAP ABI drift":
  exec("nim check --hints:off --warnings:off src/nimclap.nim")
  exec("nim r --hints:off tests/tabi.nim")

task build_example_template, "Build the C plugin template as a CLAP plugin":
  when defined(windows):
    exec "nim compile -g --app:lib --passL:\"-static-libgcc -static-libstdc++\" -o:build/plugin_template.clap examples/plugin_template.nim"
  elif defined(macosx):
    exec "nim compile -g --app:lib -o:build/plugin_template.clap examples/plugin_template.nim"
  else:  # Linux and other Unix-like systems
    exec "nim compile -g --app:lib --passL:\"-static-libgcc\" -o:build/plugin_template.clap examples/plugin_template.nim"

task build_hello, "Build hello clap":
  when defined(windows):
    exec "nim compile -g --app:lib --passL:\"-static-libgcc -static-libstdc++\" -o:build/hello_clap.clap examples/hello_clap.nim"
  elif defined(macosx):
    exec "nim compile -g --app:lib -o:build/hello_clap.clap examples/hello_clap.nim"
  else:  # Linux and other Unix-like systems
    exec "nim compile -g --app:lib --passL:\"-static-libgcc\" -o:build/hello_clap.clap examples/hello_clap.nim"

task build_hello2, "Build hello 2 clap":
  when defined(windows):
    exec "nim compile -g --app:lib --passL:\"-static-libgcc -static-libstdc++\" -o:build/hello_clap_02.clap examples/hello_clap_02.nim"
  elif defined(macosx):
    exec "nim compile -g --app:lib -o:build/hello_clap_02.clap examples/hello_clap_02.nim"
  else:  # Linux and other Unix-like systems
    exec "nim compile -g --app:lib --passL:\"-static-libgcc\" -o:build/hello_clap_02.clap examples/hello_clap_02.nim"

task build_clap_loader, "Build the CLAP plugin loader test tool":
  when defined(windows):
    exec "gcc -o build//clap_loader.exe tests/clap_loader.c"
  else:
    exec "gcc -o build//clap_loader tests/clap_loader.c -ldl"


task generate_docs, "Generate Documentation":
  exec "nim doc --project --outdir:docs ./src/nimclap.nim"
  exec "python -m http.server 7000 --directory docs"








