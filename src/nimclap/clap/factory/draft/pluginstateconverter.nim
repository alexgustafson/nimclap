import ../../id, ../../universalpluginid, ../../stream, ../../version

type PluginStateConverterDescriptor* {.bycopy.} = object
  clapVersion*: Version
  srcPluginId*: UniversalPluginId
  dstPluginId*: UniversalPluginId
  id*: cstring
  ##  eg: "com.u-he.diva-converter", mandatory
  name*: cstring
  ##  eg: "Diva Converter", mandatory
  vendor*: cstring
  ##  eg: "u-he"
  version*: cstring
  ##  eg: 1.1.5
  description*: cstring ##  eg: "Official state converter for u-he Diva."

##  This interface provides a mechanism for the host to convert a plugin state and its automation
##  points to a new plugin.
##
##  This is useful to convert from one plugin ABI to another one.
##  This is also useful to offer an upgrade path: from EQ version 1 to EQ version 2.
##  This can also be used to convert the state of a plugin that isn't maintained anymore into
##  another plugin that would be similar.

type PluginStateConverter* {.bycopy.} = object
  desc*: ptr PluginStateConverterDescriptor
  converterData*: pointer
  ##  Destroy the converter.
  destroy*: proc(`converter`: ptr PluginStateConverter) {.cdecl.}
  ##  Converts the input state to a state usable by the destination plugin.
  ##
  ##  error_buffer is a place holder of error_buffer_size bytes for storing a null-terminated
  ##  error message in case of failure, which can be displayed to the user.
  ##
  ##  Returns true on success.
  ##  [thread-safe]
  convertState*: proc(
    `converter`: ptr PluginStateConverter,
    src: ptr Istream,
    dst: ptr Ostream,
    errorBuffer: cstring,
    errorBufferSize: csize,
  ): bool {.cdecl.}
  ##  Converts a normalized value.
  ##  Returns true on success.
  ##  [thread-safe]
  convertNormalizedValue*: proc(
    `converter`: ptr PluginStateConverter,
    srcParamId: Id,
    srcNormalizedValue: cdouble,
    dstParamId: ptr Id,
    dstNormalizedValue: ptr cdouble,
  ): bool {.cdecl.}
  ##  Converts a plain value.
  ##  Returns true on success.
  ##  [thread-safe]
  convertPlainValue*: proc(
    `converter`: ptr PluginStateConverter,
    srcParamId: Id,
    srcPlainValue: cdouble,
    dstParamId: ptr Id,
    dstPlainValue: ptr cdouble,
  ): bool {.cdecl.}

##  Factory identifier

let pluginStateConverterFactoryId*: UncheckedArray[char] =
  "clap.plugin-state-converter-factory/1"

##  List all the plugin state converters available in the current DSO.

type PluginStateConverterFactory* {.bycopy.} = object
  ##  Get the number of converters.
  ##  [thread-safe]
  count*: proc(factory: ptr PluginStateConverterFactory): uint32 {.cdecl.}
  ##  Retrieves a plugin state converter descriptor by its index.
  ##  Returns null in case of error.
  ##  The descriptor must not be freed.
  ##  [thread-safe]
  getDescriptor*: proc(
    factory: ptr PluginStateConverterFactory, index: uint32
  ): ptr PluginStateConverterDescriptor {.cdecl.}
  ##  Create a plugin state converter by its converter_id.
  ##  The returned pointer must be freed by calling converter->destroy(converter);
  ##  Returns null in case of error.
  ##  [thread-safe]
  create*: proc(
    factory: ptr PluginStateConverterFactory, converterId: cstring
  ): ptr PluginStateConverter {.cdecl.}
