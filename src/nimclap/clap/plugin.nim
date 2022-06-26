import
  private/macros, host, process, plugin-features

type
  ClapPluginDescriptorT* {.bycopy.} = object
    clapVersion*: ClapVersionT ##  initialized to CLAP_VERSION
                             ##  Mandatory fields must be set and must not be blank.
                             ##  Otherwise the fields can be null or blank, though it is safer to make them blank.
    id*: cstring               ##  eg: "com.u-he.diva", mandatory
    name*: cstring             ##  eg: "Diva", mandatory
    vendor*: cstring           ##  eg: "u-he"
    url*: cstring              ##  eg: "https://u-he.com/products/diva/"
    manualUrl*: cstring        ##  eg: "https://dl.u-he.com/manuals/plugins/diva/Diva-user-guide.pdf"
    supportUrl*: cstring       ##  eg: "https://u-he.com/support/"
    version*: cstring          ##  eg: "1.4.4"
    description*: cstring ##  eg: "The spirit of analogue"
                        ##  Arbitrary list of keywords.
                        ##  They can be matched by the host indexer and used to classify the plugin.
                        ##  The array of pointers must be null terminated.
                        ##  For some standard features see plugin-features.h
    features*: cstringArray

  ClapPluginT* {.bycopy.} = object
    desc*: ptr ClapPluginDescriptorT
    pluginData*: pointer ##  reserved pointer for the plugin
                       ##  Must be called after creating the plugin.
                       ##  If init returns false, the host must destroy the plugin instance.
                       ##  [main-thread]
    init*: proc (plugin: ptr ClapPlugin): bool ##  Free the plugin and its resources.
                                         ##  It is not required to deactivate the plugin prior to this call.
                                         ##  [main-thread & !active]
    destroy*: proc (plugin: ptr ClapPlugin) ##  Activate and deactivate the plugin.
                                       ##  In this call the plugin may allocate memory and prepare everything needed for the process
                                       ##  call. The process's sample rate will be constant and process's frame count will included in
                                       ##  the [min, max] range, which is bounded by [1, INT32_MAX].
                                       ##  Once activated the latency and port configuration must remain constant, until deactivation.
                                       ##
                                       ##  [main-thread & !active_state]
    activate*: proc (plugin: ptr ClapPlugin; sampleRate: cdouble;
                   minFramesCount: uint32T; maxFramesCount: uint32T): bool ##  [main-thread & active_state]
    deactivate*: proc (plugin: ptr ClapPlugin) ##  Call start processing before processing.
                                          ##  [audio-thread & active_state & !processing_state]
    startProcessing*: proc (plugin: ptr ClapPlugin): bool ##  Call stop processing before sending the plugin to sleep.
                                                    ##  [audio-thread & active_state & processing_state]
    stopProcessing*: proc (plugin: ptr ClapPlugin) ##  - Clears all buffers, performs a full reset of the processing state (filters, oscillators,
                                              ##    enveloppes, lfo, ...) and kills all voices.
                                              ##  - The parameter's value remain unchanged.
                                              ##  - clap_process.steady_time may jump backward.
                                              ##
                                              ##  [audio-thread & active_state]
    reset*: proc (plugin: ptr ClapPlugin) ##  process audio, events, ...
                                     ##  [audio-thread & active_state & processing_state]
    process*: proc (plugin: ptr ClapPlugin; process: ptr ClapProcessT): ClapProcessStatus ##  Query an extension.
                                                                                 ##  The returned pointer is owned by the plugin.
                                                                                 ##  [thread-safe]
    getExtension*: proc (plugin: ptr ClapPlugin; id: cstring): pointer ##  Called by the host on the main thread in response to a previous call to:
                                                               ##    host->request_callback(host);
                                                               ##  [main-thread]
    onMainThread*: proc (plugin: ptr ClapPlugin)

