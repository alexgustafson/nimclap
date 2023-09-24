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

import
  ../../private/std, ../../private/macros, ../../version

##  Use it to retrieve const clap_preset_discovery_factory_t* from
##  clap_plugin_entry.get_factory()

let CLAP_PRESET_DISCOVERY_FACTORY_ID*: UncheckedArray[char] = "clap.preset-discovery-factory/draft-2"

type
  clap_preset_discovery_location_kind* = enum ##  The preset are located in a file on the OS filesystem.
                                           ##  The location is then a path which works with the OS file system functions (open, stat, ...)
                                           ##  So both '/' and '\' shall work on Windows as a separator.
    CLAP_PRESET_DISCOVERY_LOCATION_FILE = 0, ##  The preset is bundled within the plugin DSO itself.
                                          ##  The location must then be null, as the preset are within the plugin itsel and then the plugin
                                          ##  will act as a preset container.
    CLAP_PRESET_DISCOVERY_LOCATION_PLUGIN = 1


type
  clap_preset_discovery_flags* = enum ##  This is for factory or sound-pack presets.
    CLAP_PRESET_DISCOVERY_IS_FACTORY_CONTENT = 1 shl 0, ##  This is for user presets.
    CLAP_PRESET_DISCOVERY_IS_USER_CONTENT = 1 shl 1, ##  This location is meant for demo presets, those are preset which may trigger
                                                ##  some limitation in the plugin because they require additional features which the user
                                                ##  needs to purchase or the content itself needs to be bought and is only available in
                                                ##  demo mode.
    CLAP_PRESET_DISCOVERY_IS_DEMO_CONTENT = 1 shl 2, ##  This preset is a user's favorite
    CLAP_PRESET_DISCOVERY_IS_FAVORITE = 1 shl 3


##  TODO: move clap_timestamp_t, CLAP_TIMESTAMP_UNKNOWN and clap_plugin_id_t to parent files once we
##  settle with preset discovery
##  This type defines a timestamp: the number of seconds since UNIX EPOCH.
##  See C's time_t time(time_t *).

type
  clap_timestamp* = uint64

##  Value for unknown timestamp.

let CLAP_TIMESTAMP_UNKNOWN*: clap_timestamp = 0

##  Pair of plugin ABI and plugin identifier

type
  clap_plugin_id* {.bycopy.} = object
    ##  The plugin ABI name, in lowercase.
    ##  eg: "clap"
    abi*: cstring
    ##  The plugin ID, for example "com.u-he.Diva".
    ##  If the ABI rely upon binary plugin ids, then they shall be hex encoded (lower case).
    id*: cstring


##  Receiver that receives the metadata for a single preset file.
##  The host would define the various callbacks in this interface and the preset parser function
##  would then call them.
##
##  This interface isn't thread-safe.

type
  clap_preset_discovery_metadata_receiver* {.bycopy.} = object
    receiver_data*: pointer
    ##  reserved pointer for the metadata receiver
    ##  If there is an error reading metadata from a file this should be called with an error
    ##  message.
    ##  os_error: the operating system error, if applicable. If not applicable set it to a non-error
    ##  value, eg: 0 on unix and Windows.
    on_error*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                   os_error: int32; error_message: cstring) {.cdecl.}
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
    ##  If the function returns false, the the provider must stop calling back into the receiver.
    begin_preset*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                       name: cstring; load_key: cstring): bool {.cdecl.}
    ##  Adds a plug-in id that this preset can be used with.
    add_plugin_id*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                        plugin_id: ptr clap_plugin_id) {.cdecl.}
    ##  Sets the sound pack to which the preset belongs to.
    set_soundpack_id*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                           soundpack_id: cstring) {.cdecl.}
    ##  Sets the flags, see clap_preset_discovery_flags.
    ##  If unset, they are then inherited from the location.
    set_flags*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                    flags: uint32) {.cdecl.}
    ##  Adds a creator name for the preset.
    add_creator*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                      creator: cstring) {.cdecl.}
    ##  Sets a description of the preset.
    set_description*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                          description: cstring) {.cdecl.}
    ##  Sets the creation time and last modification time of the preset.
    ##  If one of the times isn't known, set it to CLAP_TIMESTAMP_UNKNOWN.
    ##  If this function is not called, then the indexer may look at the file's creation and
    ##  modification time.
    set_timestamps*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                         creation_time: clap_timestamp;
                         modification_time: clap_timestamp) {.cdecl.}
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
    add_feature*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                      feature: cstring) {.cdecl.}
    ##  Adds extra information to the metadata.
    add_extra_info*: proc (receiver: ptr clap_preset_discovery_metadata_receiver;
                         key: cstring; value: cstring) {.cdecl.}

  clap_preset_discovery_filetype* {.bycopy.} = object
    name*: cstring
    description*: cstring
    ##  optional
    ##  `.' isn't included in the string.
    ##  If empty or NULL then every file should be matched.
    file_extension*: cstring


##  Defines a place in which to search for presets

type
  clap_preset_discovery_location* {.bycopy.} = object
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

type
  clap_preset_discovery_soundpack* {.bycopy.} = object
    flags*: uint32
    ##  see enum clap_preset_discovery_flags
    id*: cstring
    ##  sound pack identifier
    name*: cstring
    ##  name of this sound pack
    description*: cstring
    ##  optional, reasonably short description of the sound pack
    homepage_url*: cstring
    ##  optional, url to the pack's homepage
    vendor*: cstring
    ##  optional, sound pack's vendor
    image_path*: cstring
    ##  optional, an image on disk
    release_timestamp*: clap_timestamp
    ##  release date, CLAP_TIMESTAMP_UNKNOWN if unavailable


##  Describes a preset provider

type
  clap_preset_discovery_provider_descriptor* {.bycopy.} = object
    clap_version*: clap_version
    ##  initialized to CLAP_VERSION
    id*: cstring
    ##  see plugin.h for advice on how to choose a good identifier
    name*: cstring
    ##  eg: "Diva's preset provider"
    vendor*: cstring
    ##  optional, eg: u-he


##  This interface isn't thread-safe.

type
  clap_preset_discovery_provider* {.bycopy.} = object
    desc*: ptr clap_preset_discovery_provider_descriptor
    provider_data*: pointer
    ##  reserved pointer for the provider
    ##  Initialize the preset provider.
    ##  It should declare all its locations, filetypes and sound packs.
    ##  Returns false if initialization failed.
    init*: proc (provider: ptr clap_preset_discovery_provider): bool {.cdecl.}
    ##  Destroys the preset provider
    destroy*: proc (provider: ptr clap_preset_discovery_provider) {.cdecl.}
    ##  reads metadata from the given file and passes them to the metadata receiver
    get_metadata*: proc (provider: ptr clap_preset_discovery_provider;
                       location_kind: uint32; location: cstring; metadata_receiver: ptr clap_preset_discovery_metadata_receiver): bool {.
        cdecl.}
    ##  Query an extension.
    ##  The returned pointer is owned by the provider.
    ##  It is forbidden to call it before provider->init().
    ##  You can call it within provider->init() call, and after.
    get_extension*: proc (provider: ptr clap_preset_discovery_provider;
                        extension_id: cstring): pointer {.cdecl.}


##  This interface isn't thread-safe

type
  clap_preset_discovery_indexer* {.bycopy.} = object
    clap_version*: clap_version
    ##  initialized to CLAP_VERSION
    name*: cstring
    ##  eg: "Bitwig Studio"
    vendor*: cstring
    ##  optional, eg: "Bitwig GmbH"
    url*: cstring
    ##  optional, eg: "https://bitwig.com"
    version*: cstring
    ##  optional, eg: "4.3", see plugin.h for advice on how to format the version
    indexer_data*: pointer
    ##  reserved pointer for the indexer
    ##  Declares a preset filetype.
    ##  Don't callback into the provider during this call.
    ##  Returns false if the filetype is invalid.
    declare_filetype*: proc (indexer: ptr clap_preset_discovery_indexer;
                           filetype: ptr clap_preset_discovery_filetype): bool {.
        cdecl.}
    ##  Declares a preset location.
    ##  Don't callback into the provider during this call.
    ##  Returns false if the location is invalid.
    declare_location*: proc (indexer: ptr clap_preset_discovery_indexer;
                           location: ptr clap_preset_discovery_location): bool {.
        cdecl.}
    ##  Declares a sound pack.
    ##  Don't callback into the provider during this call.
    ##  Returns false if the sound pack is invalid.
    declare_soundpack*: proc (indexer: ptr clap_preset_discovery_indexer;
                            soundpack: ptr clap_preset_discovery_soundpack): bool {.
        cdecl.}
    ##  Query an extension.
    ##  The returned pointer is owned by the indexer.
    ##  It is forbidden to call it before provider->init().
    ##  You can call it within provider->init() call, and after.
    get_extension*: proc (indexer: ptr clap_preset_discovery_indexer;
                        extension_id: cstring): pointer {.cdecl.}


##  Every methods in this factory must be thread-safe.
##  It is encouraged to perform preset indexing in background threads, maybe even in background
##  process.
##
##  The host may use clap_plugin_invalidation_factory to detect filesystem changes
##  which may change the factory's content.

type
  clap_preset_discovery_factory* {.bycopy.} = object
    ##  Get the number of preset providers available.
    ##  [thread-safe]
    count*: proc (factory: ptr clap_preset_discovery_factory): uint32 {.cdecl.}
    ##  Retrieves a preset provider descriptor by its index.
    ##  Returns null in case of error.
    ##  The descriptor must not be freed.
    ##  [thread-safe]
    get_descriptor*: proc (factory: ptr clap_preset_discovery_factory; index: uint32): ptr clap_preset_discovery_provider_descriptor {.
        cdecl.}
    ##  Create a preset provider by its id.
    ##  The returned pointer must be freed by calling preset_provider->destroy(preset_provider);
    ##  The preset provider is not allowed to use the indexer callbacks in the create method.
    ##  It is forbidden to call back into the indexer before the indexer calls provider->init().
    ##  Returns null in case of error.
    ##  [thread-safe]
    create*: proc (factory: ptr clap_preset_discovery_factory;
                 indexer: ptr clap_preset_discovery_indexer; provider_id: cstring): ptr clap_preset_discovery_provider {.
        cdecl.}

