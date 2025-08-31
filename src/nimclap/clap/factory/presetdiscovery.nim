##
##    Preset Discovery API.
##
##    Preset Discovery enables a plug-in host to identify where presets are found, what
##    extensions they have, which plug-ins they apply to, and other metadata associated with the
##    presets so that they can be indexed and searched for quickly within the plug-in host's browser.
##
##    This has a number of advantages for the user:
##    - it allows them to browse for presets from one central location in a consistent way
##    - the user can browse for presets without having to commit to a particular plug-in first
##
##    The API works as follow to index presets and presets metadata:
##    1. clap_plugin_entry.get_factory(CLAP_PRESET_DISCOVERY_FACTORY_ID)
##    2. clap_preset_discovery_factory_t.create(...)
##    3. clap_preset_discovery_provider.init() (only necessary the first time, declarations
##    can be cached)
##         `-> clap_preset_discovery_indexer.declare_filetype()
##         `-> clap_preset_discovery_indexer.declare_location()
##         `-> clap_preset_discovery_indexer.declare_soundpack() (optional)
##         `-> clap_preset_discovery_indexer.set_invalidation_watch_file() (optional)
##    4. crawl the given locations and monitor file system changes
##         `-> clap_preset_discovery_indexer.get_metadata() for each presets files
##
##    Then to load a preset, use ext/draft/preset-load.h.
##    TODO: create a dedicated repo for other plugin abi preset-load extension.
##
##    The design of this API deliberately does not define a fixed set tags or categories. It is the
##    plug-in host's job to try to intelligently map the raw list of features that are found for a
##    preset and to process this list to generate something that makes sense for the host's tagging and
##    categorization system. The reason for this is to reduce the work for a plug-in developer to add
##    Preset Discovery support for their existing preset file format and not have to be concerned with
##    all the different hosts and how they want to receive the metadata.
##
##    VERY IMPORTANT:
##    - the whole indexing process has to be **fast**
##       - clap_preset_provider->get_metadata() has to be fast and avoid unnecessary operations
##    - the whole indexing process must not be interactive
##       - don't show dialogs, windows, ...
##       - don't ask for user input
##

import ../private/std, ../private/macros, ../timestamp, ../version, ../universalpluginid

##  Use it to retrieve const clap_preset_discovery_factory_t* from
##  clap_plugin_entry.get_factory()

let presetDiscoveryFactoryId*: UncheckedArray[char] =
  "clap.preset-discovery-factory/2"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let presetDiscoveryFactoryIdCompat*: UncheckedArray[char] =
  "clap.preset-discovery-factory/draft-2"

type PresetDiscoveryLocationKind* {.pure.} = enum
  ##  The preset are located in a file on the OS filesystem.
  ##  The location is then a path which works with the OS file system functions (open, stat, ...)
  ##  So both '/' and '\' shall work on Windows as a separator.
  discoveryLocationFile = 0
    ##  The preset is bundled within the plugin DSO itself.
    ##  The location must then be null, as the preset are within the plugin itself and then the plugin
    ##  will act as a preset container.
  discoveryLocationPlugin = 1

type PresetDiscoveryFlags* {.pure.} = enum ##  This is for factory or sound-pack presets.
  discoveryIsFactoryContent = 1 shl 0 ##  This is for user presets.
  discoveryIsUserContent = 1 shl 1
    ##  This location is meant for demo presets, those are preset which may trigger
    ##  some limitation in the plugin because they require additional features which the user
    ##  needs to purchase or the content itself needs to be bought and is only available in
    ##  demo mode.
  discoveryIsDemoContent = 1 shl 2 ##  This preset is a user's favorite
  discoveryIsFavorite = 1 shl 3

##  Receiver that receives the metadata for a single preset file.
##  The host would define the various callbacks in this interface and the preset parser function
##  would then call them.
##
##  This interface isn't thread-safe.

type
  PresetDiscoveryMetadataReceiver* {.bycopy.} = object
    receiverData*: pointer
    ##  reserved pointer for the metadata receiver
    ##  If there is an error reading metadata from a file this should be called with an error
    ##  message.
    ##  os_error: the operating system error, if applicable. If not applicable set it to a non-error
    ##  value, eg: 0 on unix and Windows.
    onError*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver,
      osError: int32,
      errorMessage: cstring,
    ) {.cdecl.}
    ##  This must be called for every preset in the file and before any preset metadata is
    ##  sent with the calls below.
    ##
    ##  If the preset file is a preset container then name and load_key are mandatory, otherwise
    ##  they are optional.
    ##
    ##  The load_key is a machine friendly string used to load the preset inside the container via a
    ##  the preset-load plug-in extension. The load_key can also just be the subpath if that's what
    ##  the plugin wants but it could also be some other unique id like a database primary key or a
    ##  binary offset. It's use is entirely up to the plug-in.
    ##
    ##  If the function returns false, then the provider must stop calling back into the receiver.
    beginPreset*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, name: cstring, loadKey: cstring
    ): bool {.cdecl.}
    ##  Adds a plug-in id that this preset can be used with.
    addPluginId*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, pluginId: ptr UniversalPluginId
    ) {.cdecl.}
    ##  Sets the sound pack to which the preset belongs to.
    setSoundpackId*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, soundpackId: cstring
    ) {.cdecl.}
    ##  Sets the flags, see clap_preset_discovery_flags.
    ##  If unset, they are then inherited from the location.
    setFlags*:
      proc(receiver: ptr PresetDiscoveryMetadataReceiver, flags: uint32) {.cdecl.}
    ##  Adds a creator name for the preset.
    addCreator*:
      proc(receiver: ptr PresetDiscoveryMetadataReceiver, creator: cstring) {.cdecl.}
    ##  Sets a description of the preset.
    setDescription*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, description: cstring
    ) {.cdecl.}
    ##  Sets the creation time and last modification time of the preset.
    ##  If one of the times isn't known, set it to CLAP_TIMESTAMP_UNKNOWN.
    ##  If this function is not called, then the indexer may look at the file's creation and
    ##  modification time.
    setTimestamps*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver,
      creationTime: Timestamp,
      modificationTime: Timestamp,
    ) {.cdecl.}
    ##  Adds a feature to the preset.
    ##
    ##  The feature string is arbitrary, it is the indexer's job to understand it and remap it to its
    ##  internal categorization and tagging system.
    ##
    ##  However, the strings from plugin-features.h should be understood by the indexer and one of the
    ##  plugin category could be provided to determine if the preset will result into an audio-effect,
    ##  instrument, ...
    ##
    ##  Examples:
    ##  kick, drum, tom, snare, clap, cymbal, bass, lead, metalic, hardsync, crossmod, acid,
    ##  distorted, drone, pad, dirty, etc...
    addFeature*:
      proc(receiver: ptr PresetDiscoveryMetadataReceiver, feature: cstring) {.cdecl.}
    ##  Adds extra information to the metadata.
    addExtraInfo*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, key: cstring, value: cstring
    ) {.cdecl.}

  PresetDiscoveryFiletype* {.bycopy.} = object
    name*: cstring
    description*: cstring
    ##  optional
    ##  `.' isn't included in the string.
    ##  If empty or NULL then every file should be matched.
    fileExtension*: cstring

##  Defines a place in which to search for presets

type PresetDiscoveryLocation* {.bycopy.} = object
  flags*: uint32
  ##  see enum clap_preset_discovery_flags
  name*: cstring
  ##  name of this location
  kind*: uint32
  ##  See clap_preset_discovery_location_kind
  ##  Actual location in which to crawl presets.
  ##  For FILE kind, the location can be either a path to a directory or a file.
  ##  For PLUGIN kind, the location must be null.
  location*: cstring

##  Describes an installed sound pack.

type PresetDiscoverySoundpack* {.bycopy.} = object
  flags*: uint32
  ##  see enum clap_preset_discovery_flags
  id*: cstring
  ##  sound pack identifier
  name*: cstring
  ##  name of this sound pack
  description*: cstring
  ##  optional, reasonably short description of the sound pack
  homepageUrl*: cstring
  ##  optional, url to the pack's homepage
  vendor*: cstring
  ##  optional, sound pack's vendor
  imagePath*: cstring
  ##  optional, an image on disk
  releaseTimestamp*: Timestamp ##  release date, CLAP_TIMESTAMP_UNKNOWN if unavailable

##  Describes a preset provider

type PresetDiscoveryProviderDescriptor* {.bycopy.} = object
  clapVersion*: Version
  ##  initialized to CLAP_VERSION
  id*: cstring
  ##  see plugin.h for advice on how to choose a good identifier
  name*: cstring
  ##  eg: "Diva's preset provider"
  vendor*: cstring ##  optional, eg: u-he

##  This interface isn't thread-safe.

type PresetDiscoveryProvider* {.bycopy.} = object
  desc*: ptr PresetDiscoveryProviderDescriptor
  providerData*: pointer
  ##  reserved pointer for the provider
  ##  Initialize the preset provider.
  ##  It should declare all its locations, filetypes and sound packs.
  ##  Returns false if initialization failed.
  init*: proc(provider: ptr PresetDiscoveryProvider): bool {.cdecl.}
  ##  Destroys the preset provider
  destroy*: proc(provider: ptr PresetDiscoveryProvider) {.cdecl.}
  ##  reads metadata from the given file and passes them to the metadata receiver
  ##  Returns true on success.
  getMetadata*: proc(
    provider: ptr PresetDiscoveryProvider,
    locationKind: uint32,
    location: cstring,
    metadataReceiver: ptr PresetDiscoveryMetadataReceiver,
  ): bool {.cdecl.}
  ##  Query an extension.
  ##  The returned pointer is owned by the provider.
  ##  It is forbidden to call it before provider->init().
  ##  You can call it within provider->init() call, and after.
  getExtension*:
    proc(provider: ptr PresetDiscoveryProvider, extensionId: cstring): pointer {.cdecl.}

##  This interface isn't thread-safe

type PresetDiscoveryIndexer* {.bycopy.} = object
  clapVersion*: Version
  ##  initialized to CLAP_VERSION
  name*: cstring
  ##  eg: "Bitwig Studio"
  vendor*: cstring
  ##  optional, eg: "Bitwig GmbH"
  url*: cstring
  ##  optional, eg: "https://bitwig.com"
  version*: cstring
  ##  optional, eg: "4.3", see plugin.h for advice on how to format the version
  indexerData*: pointer
  ##  reserved pointer for the indexer
  ##  Declares a preset filetype.
  ##  Don't callback into the provider during this call.
  ##  Returns false if the filetype is invalid.
  declareFiletype*: proc(
    indexer: ptr PresetDiscoveryIndexer, filetype: ptr PresetDiscoveryFiletype
  ): bool {.cdecl.}
  ##  Declares a preset location.
  ##  Don't callback into the provider during this call.
  ##  Returns false if the location is invalid.
  declareLocation*: proc(
    indexer: ptr PresetDiscoveryIndexer, location: ptr PresetDiscoveryLocation
  ): bool {.cdecl.}
  ##  Declares a sound pack.
  ##  Don't callback into the provider during this call.
  ##  Returns false if the sound pack is invalid.
  declareSoundpack*: proc(
    indexer: ptr PresetDiscoveryIndexer, soundpack: ptr PresetDiscoverySoundpack
  ): bool {.cdecl.}
  ##  Query an extension.
  ##  The returned pointer is owned by the indexer.
  ##  It is forbidden to call it before provider->init().
  ##  You can call it within provider->init() call, and after.
  getExtension*:
    proc(indexer: ptr PresetDiscoveryIndexer, extensionId: cstring): pointer {.cdecl.}

##  Every methods in this factory must be thread-safe.
##  It is encouraged to perform preset indexing in background threads, maybe even in background
##  process.
##
##  The host may use clap_plugin_invalidation_factory to detect filesystem changes
##  which may change the factory's content.

type PresetDiscoveryFactory* {.bycopy.} = object
  ##  Get the number of preset providers available.
  ##  [thread-safe]
  count*: proc(factory: ptr PresetDiscoveryFactory): uint32 {.cdecl.}
  ##  Retrieves a preset provider descriptor by its index.
  ##  Returns null in case of error.
  ##  The descriptor must not be freed.
  ##  [thread-safe]
  getDescriptor*: proc(
    factory: ptr PresetDiscoveryFactory, index: uint32
  ): ptr PresetDiscoveryProviderDescriptor {.cdecl.}
  ##  Create a preset provider by its id.
  ##  The returned pointer must be freed by calling preset_provider->destroy(preset_provider);
  ##  The preset provider is not allowed to use the indexer callbacks in the create method.
  ##  It is forbidden to call back into the indexer before the indexer calls provider->init().
  ##  Returns null in case of error.
  ##  [thread-safe]
  create*: proc(
    factory: ptr PresetDiscoveryFactory,
    indexer: ptr PresetDiscoveryIndexer,
    providerId: cstring,
  ): ptr PresetDiscoveryProvider {.cdecl.}
