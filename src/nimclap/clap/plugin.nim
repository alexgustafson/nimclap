import version
import
  private/macros, host, process, pluginfeatures

type
  clap_plugin_descriptor* {.bycopy.} = object
    clap_version*: clap_version
    ##  initialized to CLAP_VERSION
    ##  Mandatory fields must be set and must not be blank.
    ##  Otherwise the fields can be null or blank, though it is safer to make them blank.
    ##
    ##  Some indications regarding id and version
    ##  - id is an arbitrary string which should be unique to your plugin,
    ##    we encourage you to use a reverse URI eg: "com.u-he.diva"
    ##  - version is an arbitrary string which describes a plugin,
    ##    it is useful for the host to understand and be able to compare two different
    ##    version strings, so here is a regex like expression which is likely to be
    ##    understood by most hosts: MAJOR(.MINOR(.REVISION)?)?( (Alpha|Beta) XREV)?
    id*: cstring
    ##  eg: "com.u-he.diva", mandatory
    name*: cstring
    ##  eg: "Diva", mandatory
    vendor*: cstring
    ##  eg: "u-he"
    url*: cstring
    ##  eg: "https://u-he.com/products/diva/"
    manual_url*: cstring
    ##  eg: "https://dl.u-he.com/manuals/plugins/diva/Diva-user-guide.pdf"
    support_url*: cstring
    ##  eg: "https://u-he.com/support/"
    version*: cstring
    ##  eg: "1.4.4"
    description*: cstring
    ##  eg: "The spirit of analogue"
    ##  Arbitrary list of keywords.
    ##  They can be matched by the host indexer and used to classify the plugin.
    ##  The array of pointers must be null terminated.
    ##  For some standard features see plugin-features.h
    features*: cstringArray

  clap_plugin* {.bycopy.} = object
    desc*: ptr clap_plugin_descriptor
    plugin_data*: pointer
    ##  reserved pointer for the plugin
    ##  Must be called after creating the plugin.
    ##  If init returns false, the host must destroy the plugin instance.
    ##  If init returns true, then the plugin is initialized and in the deactivated state.
    ##  Unlike in `plugin-factory::create_plugin`, in init you have complete access to the host
    ##  and host extensions, so clap related setup activities should be done here rather than in
    ##  create_plugin.
    ##  [main-thread]
    init*: proc (plugin: ptr clap_plugin): bool {.cdecl.}
    ##  Free the plugin and its resources.
    ##  It is required to deactivate the plugin prior to this call.
    ##  [main-thread & !active]
    destroy*: proc (plugin: ptr clap_plugin) {.cdecl.}
    ##  Activate and deactivate the plugin.
    ##  In this call the plugin may allocate memory and prepare everything needed for the process
    ##  call. The process's sample rate will be constant and process's frame count will included in
    ##  the [min, max] range, which is bounded by [1, INT32_MAX].
    ##  In this call the plugin may call host-provided methods marked [being-activated].
    ##  Once activated the latency and port configuration must remain constant, until deactivation.
    ##  Returns true on success.
    ##  [main-thread & !active]
    activate*: proc (plugin: ptr clap_plugin; sample_rate: cdouble;
                   min_frames_count: uint32; max_frames_count: uint32): bool {.cdecl.}
    ##  [main-thread & active]
    deactivate*: proc (plugin: ptr clap_plugin) {.cdecl.}
    ##  Call start processing before processing.
    ##  Returns true on success.
    ##  [audio-thread & active & !processing]
    start_processing*: proc (plugin: ptr clap_plugin): bool {.cdecl.}
    ##  Call stop processing before sending the plugin to sleep.
    ##  [audio-thread & active & processing]
    stop_processing*: proc (plugin: ptr clap_plugin) {.cdecl.}
    ##  - Clears all buffers, performs a full reset of the processing state (filters, oscillators,
    ##    envelopes, lfo, ...) and kills all voices.
    ##  - The parameter's value remain unchanged.
    ##  - clap_process.steady_time may jump backward.
    ##
    ##  [audio-thread & active]
    reset*: proc (plugin: ptr clap_plugin) {.cdecl.}
    ##  process audio, events, ...
    ##  All the pointers coming from clap_process_t and its nested attributes,
    ##  are valid until process() returns.
    ##  [audio-thread & active & processing]
    process*: proc (plugin: ptr clap_plugin; process: ptr clap_process): clap_process_status {.
        cdecl.}
    ##  Query an extension.
    ##  The returned pointer is owned by the plugin.
    ##  It is forbidden to call it before plugin->init().
    ##  You can call it within plugin->init() call, and after.
    ##  [thread-safe]
    get_extension*: proc (plugin: ptr clap_plugin; id: cstring): pointer {.cdecl.}
    ##  Called by the host on the main thread in response to a previous call to:
    ##    host->request_callback(host);
    ##  [main-thread]
    on_main_thread*: proc (plugin: ptr clap_plugin) {.cdecl.}

