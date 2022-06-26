import
  ../../plugin, ../../string-sizes

var CLAP_EXT_FILE_REFERENCE*: UncheckedArray[char] = "clap.file-reference.draft/0"

## / @page File Reference
## /
## / This extension provides a way for the host to know about files which are used
## / by the plugin, like a wavetable, a sample, ...
## /
## / The host can then:
## / - collect and save
## / - search for missing files by using:
## /   - filename
## /   - hash
## /   - file size
## / - be aware that some external file references are marked as dirty and needs to be saved.
## /
## / Regarding the hashing algorithm, as of 2022 BLAKE3 seems to be the best choice in regards to
## / performances and robustness while also providing a very small pure C library with permissive
## / licensing. For more info see https://github.com/BLAKE3-team/BLAKE3
## /
## / This extension only expose one hashing algorithm on purpose.
##  This describes a file currently used by the plugin

type
  ClapFileReferenceT* {.bycopy.} = object
    resourceId*: ClapId
    belongsToPluginCollection*: bool
    pathCapacity*: csize_t     ##  [in] the number of bytes reserved in path
    pathSize*: csize_t         ##  [out] the actual length of the path, can be bigger than path_capacity
    path*: cstring ##  [in,out] path to the file on the disk, must be null terminated, and maybe
                 ##  truncated if the capacity is less than the size

  ClapPluginFileReferenceT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT): uint32T ##  returns the number of file reference this plugin has
                                              ##  [main-thread]
    ##  gets the file reference at index
    ##  returns true on success
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; index: uint32T;
              fileReference: ptr ClapFileReferenceT): bool ##  This method can be called even if the file is missing.
                                                       ##  So the plugin is encouraged to store the digest in its state.
                                                       ##
                                                       ##  digest is an array of 32 bytes.
                                                       ##
                                                       ##  [main-thread]
    getBlake3Digest*: proc (plugin: ptr ClapPluginT; resourceId: ClapId;
                          digest: ptr uint8T): bool ##  This method can be called even if the file is missing.
                                                ##  So the plugin is encouraged to store the file's size in its state.
                                                ##
                                                ##  [main-thread]
    getFileSize*: proc (plugin: ptr ClapPluginT; resourceId: ClapId; size: ptr uint64T): bool ##  updates the path to a file reference
                                                                                   ##  [main-thread]
    updatePath*: proc (plugin: ptr ClapPluginT; resourceId: ClapId; path: cstring): bool ##  [main-thread]
    saveResources*: proc (plugin: ptr ClapPluginT): bool

  ClapHostFileReference* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  informs the host that the file references have changed, the host should schedule a full rescan
                                    ##  [main-thread]
    ##  [main-thread]
    setDirty*: proc (host: ptr ClapHostT; resourceId: ClapId)

