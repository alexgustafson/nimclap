import version
import process

type
  PluginDescriptor* {.bycopy.} = object
    ## Static description of a plugin: identity, naming and the list of features
    ## used by the host to classify it.
    clapVersion*: Version
      ## Initialized to `version` (the CLAP version the plugin was built against).
    id*: cstring
      ## Mandatory. An arbitrary string which should be unique to your plugin; we
      ## encourage you to use a reverse URI, eg: "com.u-he.diva".
      ##
      ## Mandatory fields must be set and must not be blank. Otherwise the fields
      ## can be nil or blank, though it is safer to make them blank.
    name*: cstring
      ## Mandatory. eg: "Diva".
    vendor*: cstring
      ## eg: "u-he".
    url*: cstring
      ## eg: "https://u-he.com/products/diva/".
    manualUrl*: cstring
      ## eg: "https://dl.u-he.com/manuals/plugins/diva/Diva-user-guide.pdf".
    supportUrl*: cstring
      ## eg: "https://u-he.com/support/".
    version*: cstring
      ## An arbitrary string which describes the plugin version. It is useful for
      ## the host to understand and compare two version strings, so here is a
      ## regex-like expression most hosts are likely to understand:
      ## `MAJOR(.MINOR(.REVISION)?)?( (Alpha|Beta) XREV)?`. eg: "1.4.4".
    description*: cstring
      ## eg: "The spirit of analogue".
    features*: cstringArray
      ## Arbitrary, nil-terminated list of keywords. They can be matched by the
      ## host indexer and used to classify the plugin. For some standard features
      ## see the `pluginfeatures` module.

  Plugin* {.bycopy.} = object
    desc*: ptr PluginDescriptor
    pluginData*: pointer
      ## Reserved pointer for the plugin.
    init*: proc(plugin: ptr Plugin): bool {.cdecl.}
      ## Must be called after creating the plugin.
      ## If `init` returns false, the host must destroy the plugin instance.
      ## If `init` returns true, then the plugin is initialized and in the
      ## deactivated state.
      ## Unlike in `PluginFactory.createPlugin`, in `init` you have complete
      ## access to the host and host extensions, so CLAP related setup activities
      ## should be done here rather than in `createPlugin`.
      ## `[main-thread]`
    destroy*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Free the plugin and its resources.
      ## It is required to deactivate the plugin prior to this call.
      ## `[main-thread & !active]`
    activate*: proc(
      plugin: ptr Plugin,
      sampleRate: cdouble,
      minFramesCount: uint32,
      maxFramesCount: uint32,
    ): bool {.cdecl.}
      ## Activate the plugin.
      ## In this call the plugin may allocate memory and prepare everything needed
      ## for the process call. The process's sample rate will be constant and the
      ## process's frame count will be included in the `[min, max]` range, which is
      ## bounded by `[1, INT32_MAX]`.
      ## In this call the plugin may call host-provided methods marked
      ## `[being-activated]`.
      ## Once activated the latency and port configuration must remain constant,
      ## until deactivation. Returns true on success.
      ## `[main-thread & !active]`
    deactivate*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Deactivate the plugin.
      ## `[main-thread & active]`
    startProcessing*: proc(plugin: ptr Plugin): bool {.cdecl.}
      ## Call before processing. Returns true on success.
      ## `[audio-thread & active & !processing]`
    stopProcessing*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Call before sending the plugin to sleep.
      ## `[audio-thread & active & processing]`
    reset*: proc(plugin: ptr Plugin) {.cdecl.}
      ## - Clears all buffers, performs a full reset of the processing state
      ##   (filters, oscillators, envelopes, lfo, ...) and kills all voices.
      ## - The parameters' values remain unchanged.
      ## - `Process.steadyTime` may jump backward.
      ##
      ## `[audio-thread & active]`
    process*: proc(plugin: ptr Plugin, process: ptr Process): ProcessStatus {.cdecl.}
      ## Process audio, events, ...
      ## All the pointers coming from `Process` and its nested attributes are valid
      ## until `process` returns.
      ## `[audio-thread & active & processing]`
    getExtension*: proc(plugin: ptr Plugin, id: cstring): pointer {.cdecl.}
      ## Query an extension.
      ## The returned pointer is owned by the plugin.
      ## It is forbidden to call it before `Plugin.init`.
      ## You can call it within the `Plugin.init` call, and after.
      ## `[thread-safe]`
    onMainThread*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Called by the host on the main thread in response to a previous call to
      ## `Host.requestCallback`.
      ## `[main-thread]`
