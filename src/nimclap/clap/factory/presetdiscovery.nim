##
## Preset Discovery API.
##
## Preset Discovery enables a plug-in host to identify where presets are found, what
## extensions they have, which plug-ins they apply to, and other metadata associated with the
## presets so that they can be indexed and searched for quickly within the plug-in host's browser.
##
## This has a number of advantages for the user:
## - it allows them to browse for presets from one central location in a consistent way
## - the user can browse for presets without having to commit to a particular plug-in first
##
## The API works as follow to index presets and presets metadata:
## 1. `PluginEntry.getFactory(presetDiscoveryFactoryId)`
## 2. `PresetDiscoveryFactory.create(...)`
## 3. `PresetDiscoveryProvider.init` (only necessary the first time, declarations
##    can be cached)
##      -> `PresetDiscoveryIndexer.declareFiletype`
##      -> `PresetDiscoveryIndexer.declareLocation`
##      -> `PresetDiscoveryIndexer.declareSoundpack` (optional)
##      -> `PresetDiscoveryIndexer.setInvalidationWatchFile` (optional)
## 4. crawl the given locations and monitor file system changes
##      -> `PresetDiscoveryIndexer.getMetadata` for each presets files
##
## Then to load a preset, use the `ext/draft/preset-load` extension.
## TODO: create a dedicated repo for other plugin abi preset-load extension.
##
## The design of this API deliberately does not define a fixed set tags or categories. It is the
## plug-in host's job to try to intelligently map the raw list of features that are found for a
## preset and to process this list to generate something that makes sense for the host's tagging and
## categorization system. The reason for this is to reduce the work for a plug-in developer to add
## Preset Discovery support for their existing preset file format and not have to be concerned with
## all the different hosts and how they want to receive the metadata.
##
## VERY IMPORTANT:
## - the whole indexing process has to be **fast**
##    - `PresetDiscoveryProvider.getMetadata` has to be fast and avoid unnecessary operations
## - the whole indexing process must not be interactive
##    - don't show dialogs, windows, ...
##    - don't ask for user input

import ../private/std, ../private/macros, ../timestamp, ../version, ../universalpluginid

let presetDiscoveryFactoryId*: cstring =
  cstring"clap.preset-discovery-factory/2"
  ## Use it to retrieve a `PresetDiscoveryFactory` pointer from
  ## `PluginEntry.getFactory`.

let presetDiscoveryFactoryIdCompat*: cstring =
  cstring"clap.preset-discovery-factory/draft-2"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

type PresetDiscoveryLocationKind* {.pure.} = enum
  discoveryLocationFile = 0
    ## The preset are located in a file on the OS filesystem.
    ## The location is then a path which works with the OS file system functions (open, stat, ...)
    ## So both `/` and `\` shall work on Windows as a separator.
  discoveryLocationPlugin = 1
    ## The preset is bundled within the plugin DSO itself.
    ## The location must then be null, as the preset are within the plugin itself and then the plugin
    ## will act as a preset container.

type PresetDiscoveryFlags* {.pure.} = enum
  discoveryIsFactoryContent = 1 shl 0
    ## This is for factory or sound-pack presets.
  discoveryIsUserContent = 1 shl 1
    ## This is for user presets.
  discoveryIsDemoContent = 1 shl 2
    ## This location is meant for demo presets, those are preset which may trigger
    ## some limitation in the plugin because they require additional features which the user
    ## needs to purchase or the content itself needs to be bought and is only available in
    ## demo mode.
  discoveryIsFavorite = 1 shl 3
    ## This preset is a user's favorite.

type
  PresetDiscoveryMetadataReceiver* {.bycopy.} = object
    ## Receiver that receives the metadata for a single preset file.
    ## The host would define the various callbacks in this interface and the preset parser function
    ## would then call them.
    ##
    ## This interface isn't thread-safe.
    receiverData*: pointer
      ## reserved pointer for the metadata receiver
    onError*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver,
      osError: int32,
      errorMessage: cstring,
    ) {.cdecl.}
      ## If there is an error reading metadata from a file this should be called with an error
      ## message.
      ## `osError`: the operating system error, if applicable. If not applicable set it to a non-error
      ## value, eg: 0 on unix and Windows.
    beginPreset*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, name: cstring, loadKey: cstring
    ): bool {.cdecl.}
      ## This must be called for every preset in the file and before any preset metadata is
      ## sent with the calls below.
      ##
      ## If the preset file is a preset container then name and `loadKey` are mandatory, otherwise
      ## they are optional.
      ##
      ## The `loadKey` is a machine friendly string used to load the preset inside the container via a
      ## the preset-load plug-in extension. The `loadKey` can also just be the subpath if that's what
      ## the plugin wants but it could also be some other unique id like a database primary key or a
      ## binary offset. It's use is entirely up to the plug-in.
      ##
      ## If the function returns false, then the provider must stop calling back into the receiver.
    addPluginId*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, pluginId: ptr UniversalPluginId
    ) {.cdecl.}
      ## Adds a plug-in id that this preset can be used with.
    setSoundpackId*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, soundpackId: cstring
    ) {.cdecl.}
      ## Sets the sound pack to which the preset belongs to.
    setFlags*:
      proc(receiver: ptr PresetDiscoveryMetadataReceiver, flags: uint32) {.cdecl.}
      ## Sets the flags, see `PresetDiscoveryFlags`.
      ## If unset, they are then inherited from the location.
    addCreator*:
      proc(receiver: ptr PresetDiscoveryMetadataReceiver, creator: cstring) {.cdecl.}
      ## Adds a creator name for the preset.
    setDescription*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, description: cstring
    ) {.cdecl.}
      ## Sets a description of the preset.
    setTimestamps*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver,
      creationTime: Timestamp,
      modificationTime: Timestamp,
    ) {.cdecl.}
      ## Sets the creation time and last modification time of the preset.
      ## If one of the times isn't known, set it to `timestampUnknown`.
      ## If this function is not called, then the indexer may look at the file's creation and
      ## modification time.
    addFeature*:
      proc(receiver: ptr PresetDiscoveryMetadataReceiver, feature: cstring) {.cdecl.}
      ## Adds a feature to the preset.
      ##
      ## The feature string is arbitrary, it is the indexer's job to understand it and remap it to its
      ## internal categorization and tagging system.
      ##
      ## However, the strings from the `pluginfeatures` module should be understood by the indexer and one of the
      ## plugin category could be provided to determine if the preset will result into an audio-effect,
      ## instrument, ...
      ##
      ## Examples:
      ## kick, drum, tom, snare, clap, cymbal, bass, lead, metalic, hardsync, crossmod, acid,
      ## distorted, drone, pad, dirty, etc...
    addExtraInfo*: proc(
      receiver: ptr PresetDiscoveryMetadataReceiver, key: cstring, value: cstring
    ) {.cdecl.}
      ## Adds extra information to the metadata.

  PresetDiscoveryFiletype* {.bycopy.} = object
    name*: cstring
    description*: cstring
      ## optional
    fileExtension*: cstring
      ## `.` isn't included in the string.
      ## If empty or nil then every file should be matched.

type PresetDiscoveryLocation* {.bycopy.} = object
  ## Defines a place in which to search for presets
  flags*: uint32
    ## see `PresetDiscoveryFlags`
  name*: cstring
    ## name of this location
  kind*: uint32
    ## See `PresetDiscoveryLocationKind`
  location*: cstring
    ## Actual location in which to crawl presets.
    ## For FILE kind, the location can be either a path to a directory or a file.
    ## For PLUGIN kind, the location must be null.

type PresetDiscoverySoundpack* {.bycopy.} = object
  ## Describes an installed sound pack.
  flags*: uint32
    ## see `PresetDiscoveryFlags`
  id*: cstring
    ## sound pack identifier
  name*: cstring
    ## name of this sound pack
  description*: cstring
    ## optional, reasonably short description of the sound pack
  homepageUrl*: cstring
    ## optional, url to the pack's homepage
  vendor*: cstring
    ## optional, sound pack's vendor
  imagePath*: cstring
    ## optional, an image on disk
  releaseTimestamp*: Timestamp
    ## release date, `timestampUnknown` if unavailable

type PresetDiscoveryProviderDescriptor* {.bycopy.} = object
  ## Describes a preset provider
  clapVersion*: Version
    ## initialized to `version`
  id*: cstring
    ## see the `plugin` module for advice on how to choose a good identifier
  name*: cstring
    ## eg: "Diva's preset provider"
  vendor*: cstring
    ## optional, eg: u-he

type PresetDiscoveryProvider* {.bycopy.} = object
  ## This interface isn't thread-safe.
  desc*: ptr PresetDiscoveryProviderDescriptor
  providerData*: pointer
    ## reserved pointer for the provider
  init*: proc(provider: ptr PresetDiscoveryProvider): bool {.cdecl.}
    ## Initialize the preset provider.
    ## It should declare all its locations, filetypes and sound packs.
    ## Returns false if initialization failed.
  destroy*: proc(provider: ptr PresetDiscoveryProvider) {.cdecl.}
    ## Destroys the preset provider
  getMetadata*: proc(
    provider: ptr PresetDiscoveryProvider,
    locationKind: uint32,
    location: cstring,
    metadataReceiver: ptr PresetDiscoveryMetadataReceiver,
  ): bool {.cdecl.}
    ## reads metadata from the given file and passes them to the metadata receiver
    ## Returns true on success.
  getExtension*:
    proc(provider: ptr PresetDiscoveryProvider, extensionId: cstring): pointer {.cdecl.}
    ## Query an extension.
    ## The returned pointer is owned by the provider.
    ## It is forbidden to call it before `PresetDiscoveryProvider.init`.
    ## You can call it within the `PresetDiscoveryProvider.init` call, and after.

type PresetDiscoveryIndexer* {.bycopy.} = object
  ## This interface isn't thread-safe
  clapVersion*: Version
    ## initialized to `version`
  name*: cstring
    ## eg: "Bitwig Studio"
  vendor*: cstring
    ## optional, eg: "Bitwig GmbH"
  url*: cstring
    ## optional, eg: "https://bitwig.com"
  version*: cstring
    ## optional, eg: "4.3", see the `plugin` module for advice on how to format the version
  indexerData*: pointer
    ## reserved pointer for the indexer
  declareFiletype*: proc(
    indexer: ptr PresetDiscoveryIndexer, filetype: ptr PresetDiscoveryFiletype
  ): bool {.cdecl.}
    ## Declares a preset filetype.
    ## Don't callback into the provider during this call.
    ## Returns false if the filetype is invalid.
  declareLocation*: proc(
    indexer: ptr PresetDiscoveryIndexer, location: ptr PresetDiscoveryLocation
  ): bool {.cdecl.}
    ## Declares a preset location.
    ## Don't callback into the provider during this call.
    ## Returns false if the location is invalid.
  declareSoundpack*: proc(
    indexer: ptr PresetDiscoveryIndexer, soundpack: ptr PresetDiscoverySoundpack
  ): bool {.cdecl.}
    ## Declares a sound pack.
    ## Don't callback into the provider during this call.
    ## Returns false if the sound pack is invalid.
  getExtension*:
    proc(indexer: ptr PresetDiscoveryIndexer, extensionId: cstring): pointer {.cdecl.}
    ## Query an extension.
    ## The returned pointer is owned by the indexer.
    ## It is forbidden to call it before `PresetDiscoveryProvider.init`.
    ## You can call it within the `PresetDiscoveryProvider.init` call, and after.

type PresetDiscoveryFactory* {.bycopy.} = object
  ## Every methods in this factory must be thread-safe.
  ## It is encouraged to perform preset indexing in background threads, maybe even in background
  ## process.
  ##
  ## The host may use `PluginInvalidationFactory` to detect filesystem changes
  ## which may change the factory's content.
  count*: proc(factory: ptr PresetDiscoveryFactory): uint32 {.cdecl.}
    ## Get the number of preset providers available.
    ## `[thread-safe]`
  getDescriptor*: proc(
    factory: ptr PresetDiscoveryFactory, index: uint32
  ): ptr PresetDiscoveryProviderDescriptor {.cdecl.}
    ## Retrieves a preset provider descriptor by its index.
    ## Returns nil in case of error.
    ## The descriptor must not be freed.
    ## `[thread-safe]`
  create*: proc(
    factory: ptr PresetDiscoveryFactory,
    indexer: ptr PresetDiscoveryIndexer,
    providerId: cstring,
  ): ptr PresetDiscoveryProvider {.cdecl.}
    ## Create a preset provider by its id.
    ## The returned pointer must be freed by calling `PresetDiscoveryProvider.destroy`.
    ## The preset provider is not allowed to use the indexer callbacks in the create method.
    ## It is forbidden to call back into the indexer before the indexer calls `PresetDiscoveryProvider.init`.
    ## Returns nil in case of error.
    ## `[thread-safe]`
