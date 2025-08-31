# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nim wrapper for the CLAP (CLever Audio Plugin) API, enabling the development of audio plugins in Nim. The project provides bindings to the CLAP C API and helper utilities for plugin development.

## Build Commands

### Building Example Plugins
```bash
# Build the C plugin template (not fully working yet)
nimble build_c_template
```

### Testing Tools
```bash
# Build the CLAP plugin loader test tool
nimble build_clap_loader

# Test a plugin with the loader (Windows example)
tests\clap_loader.exe build\plugin-template.clap
```

### Code Generation
```bash
# Regenerate C bindings from CLAP headers
nimble generate_bindings
```

## Architecture

### Core Structure
- `src/nimclap.nim` - Main API exports and type aliases for a more Nim-friendly interface
- `src/nimclap/clap/` - Auto-generated bindings from CLAP C headers
- `examples/` - Working plugin examples based on nakst's CLAP tutorial

### Key Components
- **Plugin Implementation**: Plugins inherit from `Plugin` and implement callbacks for initialization, processing, and state management
- **Event System**: Handles MIDI note events, parameter changes, and other CLAP events through the process callback
- **Host Interface**: Plugins interact with the DAW through the `Host` interface for logging, state management, and threading
- **Extensions**: Support for audio ports, note ports, parameters, state, latency, and logging

### C Bindings Generation
The `scripts/generate_bindings.nim` script uses c2nim to convert CLAP C headers to Nim. It applies custom tweaks from `scripts/tweaks.nim` to handle specific patterns and improve the generated code.

## Development Notes

- Plugins must be compiled as dynamic libraries with `.clap` extension
- Windows builds require static linking of libgcc/libstdc++ for compatibility
- The plugin entry point must export the `clap_entry` symbol
- Voice management and audio synthesis examples are in `hello_clap.nim`