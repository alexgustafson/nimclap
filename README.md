See `examples/hello_clap.nim` for a working example. This code is based on nakst's clap
tutorial https://nakst.gitlab.io/tutorial/clap-part-1.html. Only the first bit is implemented to keep it simple.

It can be built using the nimble comamnd:
```bash
nimble build_hello
```

The plugin_template.nim version isn't working yet. This will be implemented shortly.


## Testing

### CLAP Plugin Loader

A simple C program is provided to test loading CLAP plugins and verify they export the correct symbols.

#### Building the loader

On Linux/WSL:
```bash
cd tests
gcc -o clap_loader clap_loader.c -ldl
```

On Windows (with MinGW or Visual Studio compiler):
```bash
cd tests
gcc -o clap_loader.exe clap_loader.c
```

#### Running the loader

The loader takes a path to a `.clap` plugin file as an argument:

On Linux/WSL:
```bash
./clap_loader /path/to/plugin.clap
```

On Windows:
```bash
clap_loader.exe C:\path\to\plugin.clap
```

Example with the hello_clap plugin:
```bash
# From the project root on Windows
tests\clap_loader.exe build\hello_clap.clap

# Or with full path
tests\clap_loader.exe C:\Users\alex\CLionProjects\nimclap\build\hello_clap.clap
```

The loader will:
- Load the plugin as a dynamic library
- Look for the `clap_entry` symbol
- Display the CLAP version (major.minor.revision)
- Verify the plugin exports required functions

This is useful for verifying that your Nim-compiled plugins are correctly exporting the CLAP interface.
