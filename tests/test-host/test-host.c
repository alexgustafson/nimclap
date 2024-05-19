//
// Created by alex on 11/11/23.
//
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include "../../clap/include/clap/clap.h"

const void *get_extension(const struct clap_host *host, const char *extension_id) {
    if (!strcmp(extension_id, CLAP_EXT_LOG)) {}
}


const clap_host_t clap_host = {
    .clap_version = CLAP_VERSION_INIT,
    .host_data = NULL,
    .name = "Test Host",
    .vendor = "Test Vendor",
    .url = "https://github.com/testvendor/clap_host",
    .version = "0.0.1",
    .get_extension = get_extension,
};




int main(int argc, char **argv) {

    void* handle = dlopen("./examples/my_plugin.clap", RTLD_LAZY);
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

    // Print CLAP Version
    printf("Clap Version: %d.%d.%d\n", clap_entry->clap_version.major, clap_entry->clap_version.minor, clap_entry->clap_version.revision);

    // Get the plugin factory function
    clap_plugin_factory_t* plugin_factory = (clap_plugin_factory_t*)clap_entry->get_factory("clap.plugin-factory");
    if (!plugin_factory) {
        fprintf(stderr, "Error getting variable: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }

    // Create the plugin
    const clap_plugin_t* plugin = plugin_factory->create_plugin(plugin_factory, &clap_host, "com.example.my-plugin");
    if (!plugin) {
        fprintf(stderr, "Error creating plugin: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }

    bool result = plugin->init(plugin);

    if (!result) {
        fprintf(stderr, "Error initializing plugin: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }

}