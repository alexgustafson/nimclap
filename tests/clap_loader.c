#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// Include CLAP headers from the root clap directory
#include "../clap/include/clap/entry.h"
#include "../clap/include/clap/version.h"
#include "../clap/include/clap/id.h"
#include "../clap/include/clap/factory/plugin-factory.h"
#include "../clap/include/clap/plugin.h"
#include "../clap/include/clap/host.h"
#include "../clap/include/clap/ext/note-ports.h"
#include "../clap/include/clap/ext/audio-ports.h"
#include "../clap/include/clap/process.h"
#include "../clap/include/clap/events.h"

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

// Helper functions for test event queue
static uint32_t test_input_events_size(const clap_input_events_t *list) {
    // Our extended structure that includes the standard fields plus our data
    struct test_input_events_ext {
        void *ctx;
        uint32_t(CLAP_ABI *size)(const struct clap_input_events *list);
        const clap_event_header_t *(CLAP_ABI *get)(const struct clap_input_events *list, uint32_t index);
        const clap_event_header_t** events;
        uint32_t count;
    } *test_events = (struct test_input_events_ext *)list;
    return test_events->count;
}

static const clap_event_header_t *test_input_events_get(const clap_input_events_t *list, uint32_t index) {
    struct test_input_events_ext {
        void *ctx;
        uint32_t(CLAP_ABI *size)(const struct clap_input_events *list);
        const clap_event_header_t *(CLAP_ABI *get)(const struct clap_input_events *list, uint32_t index);
        const clap_event_header_t** events;
        uint32_t count;
    } *test_events = (struct test_input_events_ext *)list;
    
    if (index >= test_events->count)
        return NULL;
    return test_events->events[index];
}

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

    // Call the init function if present
    if (clap_entry->init) {
        printf("\nCalling init('%s')...\n", plugin_path);
        bool init_result = clap_entry->init(plugin_path);
        printf("init() returned: %s\n", init_result ? "true" : "false");
        
        if (init_result) {
            // Call the get_factory function if init succeeded
            if (clap_entry->get_factory) {
                const char* factory_id = "clap.plugin-factory";
                printf("\nCalling get_factory('%s')...\n", factory_id);
                const clap_plugin_factory_t* factory = (const clap_plugin_factory_t*)clap_entry->get_factory(factory_id);
                printf("Factory pointer: %p\n", factory);
                
                if (factory) {
                    // Test factory methods
                    printf("\nTesting factory methods:\n");
                    
                    // Get plugin count
                    uint32_t plugin_count = factory->get_plugin_count(factory);
                    printf("Plugin count: %u\n", plugin_count);
                    
                    // Get plugin descriptors
                    for (uint32_t i = 0; i < plugin_count; i++) {
                        const clap_plugin_descriptor_t* desc = factory->get_plugin_descriptor(factory, i);
                        if (desc) {
                            printf("\nPlugin %u:\n", i);
                            printf("  ID: %s\n", desc->id);
                            printf("  Name: %s\n", desc->name);
                            printf("  Vendor: %s\n", desc->vendor);
                            printf("  Version: %s\n", desc->version);
                            printf("  Description: %s\n", desc->description);
                            
                            // Display features
                            printf("  Features:\n");
                            if (desc->features) {
                                const char *const *feature = desc->features;
                                int feature_count = 0;
                                while (*feature) {
                                    printf("    [%d] %s\n", feature_count, *feature);
                                    feature++;
                                    feature_count++;
                                }
                                if (feature_count == 0) {
                                    printf("    (no features registered)\n");
                                }
                            } else {
                                printf("    (features array is NULL)\n");
                            }
                            
                            // Create a minimal test host
                            clap_host_t test_host = {
                                .clap_version = CLAP_VERSION,
                                .host_data = NULL,
                                .name = "CLAP Loader Test",
                                .vendor = "Test",
                                .url = "http://test.com",
                                .version = "1.0.0",
                                .get_extension = NULL,
                                .request_restart = NULL,
                                .request_process = NULL,
                                .request_callback = NULL
                            };
                            
                            // Try to create the plugin
                            printf("\n  Attempting to create plugin with ID '%s'...\n", desc->id);
                            const clap_plugin_t* plugin = factory->create_plugin(factory, &test_host, desc->id);
                            if (plugin) {
                                printf("  Plugin created successfully!\n");
                                printf("  Plugin descriptor: %s\n", plugin->desc->name);
                                printf("  Plugin has destroy method: %s\n", plugin->destroy ? "yes" : "no");
                                
                                // Initialize the plugin
                                if (plugin->init && plugin->init(plugin)) {
                                    printf("  Plugin initialized successfully.\n");
                                    
                                    // Test CLAP_EXT_NOTE_PORTS extension
                                    printf("\n  Testing CLAP_EXT_NOTE_PORTS extension:\n");
                                    const clap_plugin_note_ports_t* note_ports = 
                                        (const clap_plugin_note_ports_t*)plugin->get_extension(plugin, CLAP_EXT_NOTE_PORTS);
                                    
                                    if (note_ports) {
                                        printf("    Note ports extension found!\n");
                                        
                                        // Check input ports
                                        uint32_t input_count = note_ports->count(plugin, true);
                                        printf("    Input note ports: %u\n", input_count);
                                        for (uint32_t j = 0; j < input_count; j++) {
                                            clap_note_port_info_t info;
                                            if (note_ports->get(plugin, j, true, &info)) {
                                                printf("      Input port %u:\n", j);
                                                printf("        ID: %u\n", info.id);
                                                printf("        Name: %s\n", info.name);
                                                printf("        Supported dialects: 0x%x", info.supported_dialects);
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_CLAP) printf(" CLAP");
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_MIDI) printf(" MIDI");
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_MIDI_MPE) printf(" MIDI_MPE");
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_MIDI2) printf(" MIDI2");
                                                printf("\n");
                                                printf("        Preferred dialect: 0x%x\n", info.preferred_dialect);
                                            }
                                        }
                                        
                                        // Check output ports
                                        uint32_t output_count = note_ports->count(plugin, false);
                                        printf("    Output note ports: %u\n", output_count);
                                        for (uint32_t j = 0; j < output_count; j++) {
                                            clap_note_port_info_t info;
                                            if (note_ports->get(plugin, j, false, &info)) {
                                                printf("      Output port %u:\n", j);
                                                printf("        ID: %u\n", info.id);
                                                printf("        Name: %s\n", info.name);
                                                printf("        Supported dialects: 0x%x", info.supported_dialects);
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_CLAP) printf(" CLAP");
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_MIDI) printf(" MIDI");
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_MIDI_MPE) printf(" MIDI_MPE");
                                                if (info.supported_dialects & CLAP_NOTE_DIALECT_MIDI2) printf(" MIDI2");
                                                printf("\n");
                                                printf("        Preferred dialect: 0x%x\n", info.preferred_dialect);
                                            }
                                        }
                                    } else {
                                        printf("    Note ports extension not found.\n");
                                    }
                                    
                                    // Test CLAP_EXT_AUDIO_PORTS extension
                                    printf("\n  Testing CLAP_EXT_AUDIO_PORTS extension:\n");
                                    const clap_plugin_audio_ports_t* audio_ports = 
                                        (const clap_plugin_audio_ports_t*)plugin->get_extension(plugin, CLAP_EXT_AUDIO_PORTS);
                                    
                                    if (audio_ports) {
                                        printf("    Audio ports extension found!\n");
                                        
                                        // Check input ports
                                        uint32_t input_count = audio_ports->count(plugin, true);
                                        printf("    Input audio ports: %u\n", input_count);
                                        for (uint32_t j = 0; j < input_count; j++) {
                                            clap_audio_port_info_t info;
                                            if (audio_ports->get(plugin, j, true, &info)) {
                                                printf("      Input port %u:\n", j);
                                                printf("        ID: %u\n", info.id);
                                                printf("        Name: %s\n", info.name);
                                                printf("        Channel count: %u\n", info.channel_count);
                                                printf("        Port type: %s\n", info.port_type ? info.port_type : "(unspecified)");
                                                printf("        Flags: 0x%x", info.flags);
                                                if (info.flags & CLAP_AUDIO_PORT_IS_MAIN) printf(" IS_MAIN");
                                                if (info.flags & CLAP_AUDIO_PORT_SUPPORTS_64BITS) printf(" SUPPORTS_64BITS");
                                                if (info.flags & CLAP_AUDIO_PORT_PREFERS_64BITS) printf(" PREFERS_64BITS");
                                                if (info.flags & CLAP_AUDIO_PORT_REQUIRES_COMMON_SAMPLE_SIZE) printf(" REQUIRES_COMMON_SAMPLE_SIZE");
                                                printf("\n");
                                                printf("        In-place pair: %u%s\n", info.in_place_pair, 
                                                       info.in_place_pair == CLAP_INVALID_ID ? " (none)" : "");
                                            }
                                        }
                                        
                                        // Check output ports
                                        uint32_t output_count = audio_ports->count(plugin, false);
                                        printf("    Output audio ports: %u\n", output_count);
                                        for (uint32_t j = 0; j < output_count; j++) {
                                            clap_audio_port_info_t info;
                                            if (audio_ports->get(plugin, j, false, &info)) {
                                                printf("      Output port %u:\n", j);
                                                printf("        ID: %u\n", info.id);
                                                printf("        Name: %s\n", info.name);
                                                printf("        Channel count: %u\n", info.channel_count);
                                                printf("        Port type: %s\n", info.port_type ? info.port_type : "(unspecified)");
                                                printf("        Flags: 0x%x", info.flags);
                                                if (info.flags & CLAP_AUDIO_PORT_IS_MAIN) printf(" IS_MAIN");
                                                if (info.flags & CLAP_AUDIO_PORT_SUPPORTS_64BITS) printf(" SUPPORTS_64BITS");
                                                if (info.flags & CLAP_AUDIO_PORT_PREFERS_64BITS) printf(" PREFERS_64BITS");
                                                if (info.flags & CLAP_AUDIO_PORT_REQUIRES_COMMON_SAMPLE_SIZE) printf(" REQUIRES_COMMON_SAMPLE_SIZE");
                                                printf("\n");
                                                printf("        In-place pair: %u%s\n", info.in_place_pair, 
                                                       info.in_place_pair == CLAP_INVALID_ID ? " (none)" : "");
                                            }
                                        }
                                    } else {
                                        printf("    Audio ports extension not found.\n");
                                    }
                                    
                                    // Test plugin lifecycle methods
                                    printf("\n  Testing plugin lifecycle:\n");
                                    
                                    // Test activate()
                                    if (plugin->activate) {
                                        printf("    Testing activate()...\n");
                                        double sample_rate = 48000.0;
                                        uint32_t min_frames = 32;
                                        uint32_t max_frames = 1024;
                                        bool activate_result = plugin->activate(plugin, sample_rate, min_frames, max_frames);
                                        printf("    activate(%.1f Hz, %u-%u frames) returned: %s\n", 
                                               sample_rate, min_frames, max_frames, activate_result ? "true" : "false");
                                        
                                        if (activate_result) {
                                            // Test start_processing()
                                            if (plugin->start_processing) {
                                                printf("\n    Testing start_processing()...\n");
                                                bool start_result = plugin->start_processing(plugin);
                                                printf("    start_processing() returned: %s\n", start_result ? "true" : "false");
                                                
                                                if (start_result) {
                                                    // Test process()
                                                    if (plugin->process) {
                                                        printf("\n    Testing process()...\n");
                                                        
                                                        // Create minimal process context with stereo output
                                                        float dummy_output_left[1024] = {0};
                                                        float dummy_output_right[1024] = {0};
                                                        float* output_ptrs[2] = {dummy_output_left, dummy_output_right};
                                                        
                                                        clap_audio_buffer_t audio_outputs = {
                                                            .data32 = output_ptrs,
                                                            .data64 = NULL,
                                                            .channel_count = 2,  // Stereo
                                                            .latency = 0,
                                                            .constant_mask = 0
                                                        };
                                                        
                                                        // Create test events - D#4 note
                                                        const int NOTE_KEY = 63;  // D#4 (MIDI note number)
                                                        const uint32_t NOTE_ON_TIME = 100;  // Start at sample 100
                                                        const uint32_t NOTE_OFF_TIME = 400; // End at sample 400
                                                        
                                                        printf("    Creating test note events: D#4 (key=%d), on at sample %u, off at sample %u\n", 
                                                               NOTE_KEY, NOTE_ON_TIME, NOTE_OFF_TIME);
                                                        
                                                        // Create note events
                                                        clap_event_note_t note_on_event = {
                                                            .header = {
                                                                .size = sizeof(clap_event_note_t),
                                                                .time = NOTE_ON_TIME,
                                                                .space_id = CLAP_CORE_EVENT_SPACE_ID,
                                                                .type = CLAP_EVENT_NOTE_ON,
                                                                .flags = 0
                                                            },
                                                            .note_id = -1,  // Use wildcard
                                                            .port_index = 0,
                                                            .channel = 0,
                                                            .key = NOTE_KEY,
                                                            .velocity = 0.8
                                                        };
                                                        
                                                        clap_event_note_t note_off_event = {
                                                            .header = {
                                                                .size = sizeof(clap_event_note_t),
                                                                .time = NOTE_OFF_TIME,
                                                                .space_id = CLAP_CORE_EVENT_SPACE_ID,
                                                                .type = CLAP_EVENT_NOTE_OFF,
                                                                .flags = 0
                                                            },
                                                            .note_id = -1,  // Use wildcard
                                                            .port_index = 0,
                                                            .channel = 0,
                                                            .key = NOTE_KEY,
                                                            .velocity = 0.0
                                                        };
                                                        
                                                        // Create event array
                                                        const clap_event_header_t* test_events[2] = {
                                                            &note_on_event.header,
                                                            &note_off_event.header
                                                        };
                                                        
                                                        // Create input events structure that matches clap_input_events layout
                                                        struct {
                                                            void *ctx;  // Must match clap_input_events layout
                                                            uint32_t(CLAP_ABI *size)(const struct clap_input_events *list);
                                                            const clap_event_header_t *(CLAP_ABI *get)(const struct clap_input_events *list, uint32_t index);
                                                            // Our custom data after the standard fields
                                                            const clap_event_header_t** events;
                                                            uint32_t count;
                                                        } input_events = {
                                                            .ctx = NULL,
                                                            .size = test_input_events_size,
                                                            .get = test_input_events_get,
                                                            .events = test_events,
                                                            .count = 2
                                                        };
                                                        
                                                        clap_process_t process_context = {
                                                            .steady_time = -1,
                                                            .frames_count = 512,
                                                            .transport = NULL,
                                                            .audio_inputs = NULL,
                                                            .audio_outputs = &audio_outputs,
                                                            .audio_inputs_count = 0,
                                                            .audio_outputs_count = 1,
                                                            .in_events = (const clap_input_events_t*)&input_events,
                                                            .out_events = NULL
                                                        };
                                                        
                                                        clap_process_status status = plugin->process(plugin, &process_context);
                                                        printf("    process(512 frames) returned status: %d", status);
                                                        switch(status) {
                                                            case CLAP_PROCESS_ERROR: printf(" (ERROR)\n"); break;
                                                            case CLAP_PROCESS_CONTINUE: printf(" (CONTINUE)\n"); break;
                                                            case CLAP_PROCESS_CONTINUE_IF_NOT_QUIET: printf(" (CONTINUE_IF_NOT_QUIET)\n"); break;
                                                            case CLAP_PROCESS_TAIL: printf(" (TAIL)\n"); break;
                                                            case CLAP_PROCESS_SLEEP: printf(" (SLEEP)\n"); break;
                                                            default: printf(" (UNKNOWN)\n"); break;
                                                        }
                                                        
                                                        // Check if audio was generated
                                                        float max_sample = 0.0f;
                                                        int non_zero_samples = 0;
                                                        for (int i = 0; i < 512; i++) {
                                                            if (dummy_output_left[i] != 0.0f || dummy_output_right[i] != 0.0f) {
                                                                non_zero_samples++;
                                                                float sample = fabs(dummy_output_left[i]);
                                                                if (sample > max_sample) max_sample = sample;
                                                                sample = fabs(dummy_output_right[i]);
                                                                if (sample > max_sample) max_sample = sample;
                                                            }
                                                        }
                                                        printf("    Audio output: %d non-zero samples, max amplitude: %.4f\n", 
                                                               non_zero_samples, max_sample);
                                                        
                                                        // Print samples around note events for debugging
                                                        printf("    Samples around note-on (100): ");
                                                        for (int i = 98; i < 103 && i < 512; i++) {
                                                            printf("%.3f ", dummy_output_left[i]);
                                                        }
                                                        printf("\n");
                                                        
                                                        printf("    Samples around note-off (400): ");
                                                        for (int i = 398; i < 403 && i < 512; i++) {
                                                            printf("%.3f ", dummy_output_left[i]);
                                                        }
                                                        printf("\n");
                                                    }
                                                    
                                                    // Test reset()
                                                    if (plugin->reset) {
                                                        printf("\n    Testing reset()...\n");
                                                        plugin->reset(plugin);
                                                        printf("    reset() called successfully.\n");
                                                    }
                                                    
                                                    // Test stop_processing()
                                                    if (plugin->stop_processing) {
                                                        printf("\n    Testing stop_processing()...\n");
                                                        plugin->stop_processing(plugin);
                                                        printf("    stop_processing() called successfully.\n");
                                                    }
                                                }
                                            }
                                            
                                            // Test on_main_thread()
                                            if (plugin->on_main_thread) {
                                                printf("\n    Testing on_main_thread()...\n");
                                                plugin->on_main_thread(plugin);
                                                printf("    on_main_thread() called successfully.\n");
                                            }
                                            
                                            // Test deactivate()
                                            if (plugin->deactivate) {
                                                printf("\n    Testing deactivate()...\n");
                                                plugin->deactivate(plugin);
                                                printf("    deactivate() called successfully.\n");
                                            }
                                        }
                                    }
                                } else {
                                    printf("  Plugin was not initialized, skipping lifecycle tests.\n");
                                }
                                
                                // Clean up - destroy the plugin
                                if (plugin->destroy) {
                                    plugin->destroy(plugin);
                                    printf("\n  Plugin destroyed.\n");
                                }
                            } else {
                                printf("  Failed to create plugin.\n");
                            }
                        }
                    }
                }
            }
            
            // Call the deinit function before unloading
            if (clap_entry->deinit) {
                printf("\nCalling deinit()...\n");
                clap_entry->deinit();
            }
        }
    }

    // Clean up
    CLOSE_LIBRARY(handle);
    
    return 0;
}