# CLAUDE.md

This file provides guidance to AI Agents when working with code in this repository.

## Project Overview

This is a Nim wrapper for the CLAP (CLever Audio Plugin) API, enabling the development of audio plugins in Nim. The project provides bindings to the CLAP C API and helper utilities for plugin development.

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

### Code Generation
The Nim bindings are **hand-maintained** (the previous c2nim-based `scripts/`
pipeline has been removed). The upstream CLAP C headers live in the `clap/` git
submodule, pinned to a reviewed commit.

```bash
# First-time checkout of the upstream headers
git submodule update --init clap

# Report which CLAP headers changed since the last reviewed baseline
nimble check_abi

# Pull the latest upstream headers, then report drift
nimble update_clap

# Record the current submodule commit as the reviewed baseline (after the
# bindings have been reconciled with it)
nimble bless_abi
```

## Architecture

### Core Structure
- `src/nimclap.nim` - Main API exports and type aliases for a more Nim-friendly interface
- `src/nimclap/clap/` - Hand-maintained bindings, one Nim module per upstream CLAP C header
- `clap/` - git submodule with the upstream CLAP C headers (source of truth for the ABI)
- `tests/abi_tracker.nim` - git-based ABI change tracker
- `tests/clap_abi.baseline` - reviewed-commit + per-header blob hashes (generated; update via `nimble bless_abi`)
- `tests/tabi.nim` - drift gate for `nimble test`

### Key Components
- **Plugin Implementation**: Plugins inherit from `Plugin` and implement callbacks for initialization, processing, and state management
- **Event System**: Handles MIDI note events, parameter changes, and other CLAP events through the process callback
- **Host Interface**: Plugins interact with the DAW through the `Host` interface for logging, state management, and threading
- **Extensions**: Support for audio ports, note ports, parameters, state, latency, and logging

### Maintaining the Bindings
The bindings are edited by hand. Each module under `src/nimclap/clap/` mirrors
one upstream CLAP C header; doc comments are translated into Nim-oriented
documentation. When `nimble check_abi` reports that a header changed, update the
corresponding Nim module(s) by hand, then run `nimble bless_abi` to record the
new reviewed baseline. The mapping from a header to its binding strips hyphens
from the file name (e.g. `ext/audio-ports.h` -> `src/nimclap/clap/ext/audioports.nim`).

## Development Notes

- Plugins must be compiled as dynamic libraries with `.clap` extension
- Windows builds require static linking of libgcc/libstdc++ for compatibility
- The plugin entry point must export the `clap_entry` symbol
- Voice management and audio synthesis examples are in `hello_clap.nim`