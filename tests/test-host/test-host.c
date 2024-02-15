//
// Created by alex on 11/11/23.
//
#include <stdio.h>
#include <dlfcn.h>
#include "clap.h"



int main(int argc, char **argv) {
    
    void* handle = dlopen("../../examples/my_plugin.clap", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "Error loading library: %s\n", dlerror());
        return 1;
    }

    struct clap_plugin_entry* clap_entry = dlsym(handle, "clap_entry");

    if (!clap_entry) {
        fprintf(stderr, "Error getting variable: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }

    printf("Field 1: %d\n", clap_entry->clap_version);

}