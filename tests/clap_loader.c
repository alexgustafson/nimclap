#include <stdio.h>
#include <stdlib.h>

// Include CLAP headers from the root clap directory
#include "../clap/include/clap/entry.h"
#include "../clap/include/clap/version.h"

#ifdef _WIN32
    #include <windows.h>
    typedef HMODULE lib_handle_t;
    #define LOAD_LIBRARY(path) LoadLibraryA(path)
    #define GET_SYMBOL(handle, name) GetProcAddress(handle, name)
    #define CLOSE_LIBRARY(handle) FreeLibrary(handle)
    #define LIB_ERROR() "LoadLibrary failed"
#else
    #include <dlfcn.h>
    typedef void* lib_handle_t;
    #define LOAD_LIBRARY(path) dlopen(path, RTLD_LAZY | RTLD_LOCAL)
    #define GET_SYMBOL(handle, name) dlsym(handle, name)
    #define CLOSE_LIBRARY(handle) dlclose(handle)
    #define LIB_ERROR() dlerror()
#endif

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <path_to_clap_plugin>\n", argv[0]);
        return 1;
    }

    const char *plugin_path = argv[1];
    printf("Loading CLAP plugin: %s\n", plugin_path);

    // Load the dynamic library
    lib_handle_t handle = LOAD_LIBRARY(plugin_path);
    if (!handle) {
#ifdef _WIN32
        DWORD error = GetLastError();
        fprintf(stderr, "Failed to load plugin: %s\n", plugin_path);
        fprintf(stderr, "Windows error code: %lu\n", error);
        
        // Get detailed error message
        char* errorMessage = NULL;
        FormatMessageA(
            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            error,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPSTR)&errorMessage,
            0,
            NULL
        );
        if (errorMessage) {
            fprintf(stderr, "Error details: %s", errorMessage);
            LocalFree(errorMessage);
        }
#else
        fprintf(stderr, "Failed to load plugin: %s\n", LIB_ERROR());
#endif
        return 1;
    }

    // Look for the clap_entry symbol
    const clap_plugin_entry_t *clap_entry = (const clap_plugin_entry_t *)GET_SYMBOL(handle, "clap_entry");
    if (!clap_entry) {
        fprintf(stderr, "Failed to find clap_entry symbol\n");
        CLOSE_LIBRARY(handle);
        return 1;
    }

    // Read and display the CLAP version
    printf("Found clap_entry!\n");
    printf("CLAP Version: %u.%u.%u\n", 
           clap_entry->clap_version.major,
           clap_entry->clap_version.minor,
           clap_entry->clap_version.revision);

    // Check if the version is compatible (major >= 1)
    if (clap_entry->clap_version.major >= 1) {
        printf("CLAP version is compatible\n");
    } else {
        printf("CLAP version is NOT compatible (development version)\n");
    }

    // Check if function pointers are present
    printf("init function: %s\n", clap_entry->init ? "present" : "missing");
    printf("deinit function: %s\n", clap_entry->deinit ? "present" : "missing");
    printf("get_factory function: %s\n", clap_entry->get_factory ? "present" : "missing");

    // Clean up
    CLOSE_LIBRARY(handle);
    
    return 0;
}