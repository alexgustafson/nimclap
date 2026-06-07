# CLAUDE.md

This file provides guidance to AI Agents when working with code in this repository.

## Project Overview

This is a native Nim implementation of the CLAP (CLever Audio Plugin) ABI, enabling the development of audio plugins in Nim. The Nim modules re-declare the CLAP ABI directly and provide helper utilities for plugin development.

## Build Commands

### Building Example Plugins
```bash
# Build the C plugin template (not fully working yet)
nimble build_example_template
```

### Testing Tools
```bash
# Build the CLAP plugin loader test tool
nimble build_clap_loader

# Test a plugin with the loader (Windows example)
tests\clap_loader.exe build\plugin-template.clap
```

### Upstream Headers
The Nim bindings are **hand-maintained** (the previous c2nim-based `scripts/`
pipeline has been removed). The upstream CLAP C headers live in the `clap/` git
submodule, used as the reference for the ABI and by the C plugin loader.

```bash
# First-time checkout of the upstream headers
git submodule update --init clap
```

## Architecture

### Core Structure
- `src/nimclap.nim` - Main API exports and type aliases for a more Nim-friendly interface
- `src/nimclap/clap/` - Hand-maintained bindings, one Nim module per upstream CLAP C header
- `clap/` - git submodule with the upstream CLAP C headers (reference for the ABI)
- `tests/clap_loader.c` - C tool that loads a `.clap` plugin and exercises its lifecycle

### Key Components
- **Plugin Implementation**: Plugins inherit from `Plugin` and implement callbacks for initialization, processing, and state management
- **Event System**: Handles MIDI note events, parameter changes, and other CLAP events through the process callback
- **Host Interface**: Plugins interact with the DAW through the `Host` interface for logging, state management, and threading
- **Extensions**: Support for audio ports, note ports, parameters, state, latency, and logging

### Maintaining the Bindings
The bindings are edited by hand. Each module under `src/nimclap/clap/` mirrors
one upstream CLAP C header; doc comments are translated into Nim-oriented
documentation. When the upstream headers change, update the corresponding Nim
module(s) by hand. The mapping from a header to its binding strips hyphens
from the file name (e.g. `ext/audio-ports.h` -> `src/nimclap/clap/ext/audioports.nim`).

## Development Notes

- Plugins must be compiled as dynamic libraries with `.clap` extension
- Windows builds require static linking of libgcc/libstdc++ for compatibility
- The plugin entry point must export the `clap_entry` symbol
- Voice management and audio synthesis examples are in `hello_clap.nim`