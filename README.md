# nimclap

A native Nim implementation of the [CLAP](https://cleveraudio.org/) (CLever Audio
Plugin) ABI, for writing audio plugins in Nim.

`nimclap` is **not** a binding generated over a C library. It is a hand-maintained
set of Nim modules that re-declare the CLAP ABI directly — its types, structs,
function tables, constants and extensions — so plugins can be written entirely in
Nim and compiled straight to a `.clap` shared library. There is no C shim and no
runtime dependency beyond the host that loads the plugin.

The ABI is mirrored header-for-header from the upstream
[free-audio/clap](https://github.com/free-audio/clap) project. Each Nim module
corresponds to one upstream C header, with documentation translated into
Nim-oriented form.

- **Target ABI:** CLAP 1.2.8
- **Status:** early (0.1.0); the core ABI and a working plugin path are in place.

## Requirements

- Nim >= 2.0.0
- A C toolchain for linking the shared library (e.g. MinGW-w64 / gcc / clang)
- `git` — only needed for the ABI-tracking workflow (the upstream headers are a submodule)

## Installation

```bash
nimble install nimclap
```

Or add it to your `.nimble` file:

```nim
requires "nimclap"
```

## Usage

Import the package and implement the CLAP entry point, plugin factory and plugin
function tables using plain Nim:

```nim
import nimclap

let descriptor = PluginDescriptor(
  clapVersion: versionInit,
  id: "com.example.MyPlugin".cstring,
  name: "My Plugin".cstring,
  vendor: "Example".cstring,
  version: "1.0.0".cstring,
  features: allocCStringArray([pluginFeatureInstrument, pluginFeatureStereo]),
)

# ... build the Plugin, PluginFactory and PluginEntry function tables,
# then export the entry point:

var clap_entry* {.exportc, dynlib.}: PluginEntry = PluginEntry(
  clapVersion: versionInit,
  init: proc(pluginPath: cstring): bool {.cdecl.} = true,
  deinit: proc() {.cdecl.} = discard,
  getFactory: proc(id: cstring): pointer {.cdecl.} =
    if id == pluginFactoryId: cast[pointer](pluginFactory.addr) else: nil,
)
```

The `examples/` directory contains complete, working plugins:

- `examples/hello_clap.nim` — a minimal polyphonic sine synthesizer.
- `examples/hello_clap_02.nim` — the synth plus a parameter and state save/load.
- `examples/plugin_template.nim` — a fuller template covering audio/note ports,
  latency and state.

## Building a plugin

A CLAP plugin is a shared library with the `.clap` extension that exports the
`clap_entry` symbol. Compile with `--app:lib`:

```bash
nim compile --app:lib -o:build/my_plugin.clap my_plugin.nim
```

On Windows, statically link the runtime so the plugin loads without extra DLLs:

```bash
nim compile --app:lib --passL:"-static-libgcc -static-libstdc++" -o:build/my_plugin.clap my_plugin.nim
```

The bundled examples can be built with the provided nimble tasks:

```bash
nimble build_hello             # examples/hello_clap.nim
nimble build_hello2            # examples/hello_clap_02.nim
nimble build_example_template  # examples/plugin_template.nim
```

## Testing plugins

A small C loader is included to verify that a compiled plugin exports the CLAP
interface correctly and exercises its lifecycle (init, factory, extensions,
activate/process/deactivate, destroy).

Build it:

```bash
nimble build_clap_loader
```

Run it against a `.clap` file:

```bash
# Windows
build\clap_loader.exe build\hello_clap.clap

# Linux / WSL / macOS
build/clap_loader build/hello_clap.clap
```

The loader reports the CLAP version, lists the plugin descriptor and declared
ports, and runs a short audio-processing pass so you can confirm the plugin is
wired up correctly.

## Keeping the ABI in sync with upstream CLAP

Because the ABI is declared by hand, `nimclap` tracks the upstream headers with
git so changes are easy to spot. The upstream headers live in the `clap/`
submodule, pinned to a reviewed commit. That commit — together with a content
hash for every header — is recorded in `tests/clap_abi.baseline`.

First-time setup (the submodule must be checked out):

```bash
git submodule update --init clap
```

Workflow:

```bash
nimble check_abi    # report headers that drifted from the reviewed baseline
nimble update_clap  # pull the latest upstream headers, then report what changed
nimble bless_abi    # after reconciling the bindings, record the new baseline
```

`nimble check_abi` lists every added/removed/changed header, maps each to the Nim
module that needs review, and prints the textual git diff. It is informational
and always exits cleanly. The fail-on-drift gate is `nimble test`
(`tests/tabi.nim`), which compiles the library and exits non-zero when the headers
no longer match the reviewed baseline. See `tests/abi_tracker.nim` for the
implementation.

## Documentation

API documentation can be generated with Nim's documentation tool:

```bash
nim doc --project --outdir:docs ./src/nimclap.nim
```

## License

MIT. See the upstream [CLAP](https://github.com/free-audio/clap) project for the
license of the C headers tracked in the `clap/` submodule.
