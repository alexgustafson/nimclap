import
  ../../id, ../../universalpluginid, ../../stream, ../../version

type
  clap_plugin_state_converter_descriptor* {.bycopy.} = object
    clap_version*: clap_version
    src_plugin_id*: clap_universal_plugin_id
    dst_plugin_id*: clap_universal_plugin_id
    id*: cstring
    ##  eg: "com.u-he.diva-converter", mandatory
    name*: cstring
    ##  eg: "Diva Converter", mandatory
    vendor*: cstring
    ##  eg: "u-he"
    version*: cstring
    ##  eg: 1.1.5
    description*: cstring
    ##  eg: "Official state converter for u-he Diva."


##  This interface provides a mechanism for the host to convert a plugin state and its automation
##  points to a new plugin.
##
##  This is useful to convert from one plugin ABI to another one.
##  This is also useful to offer an upgrade path: from EQ version 1 to EQ version 2.
##  This can also be used to convert the state of a plugin that isn't maintained anymore into
##  another plugin that would be similar.

type
  clap_plugin_state_converter* {.bycopy.} = object
    desc*: ptr clap_plugin_state_converter_descriptor
    converter_data*: pointer
    ##  Destroy the converter.
    destroy*: proc (`converter`: ptr clap_plugin_state_converter) {.cdecl.}
    ##  Converts the input state to a state usable by the destination plugin.
    ##
    ##  error_buffer is a place holder of error_buffer_size bytes for storing a null-terminated
    ##  error message in case of failure, which can be displayed to the user.
    ##
    ##  Returns true on success.
    ##  [thread-safe]
    convert_state*: proc (`converter`: ptr clap_plugin_state_converter;
                        src: ptr clap_istream; dst: ptr clap_ostream;
                        error_buffer: cstring; error_buffer_size: csize): bool {.
        cdecl.}
    ##  Converts a normalized value.
    ##  Returns true on success.
    ##  [thread-safe]
    convert_normalized_value*: proc (`converter`: ptr clap_plugin_state_converter;
                                   src_param_id: clap_id;
                                   src_normalized_value: cdouble;
                                   dst_param_id: ptr clap_id;
                                   dst_normalized_value: ptr cdouble): bool {.cdecl.}
    ##  Converts a plain value.
    ##  Returns true on success.
    ##  [thread-safe]
    convert_plain_value*: proc (`converter`: ptr clap_plugin_state_converter;
                              src_param_id: clap_id; src_plain_value: cdouble;
                              dst_param_id: ptr clap_id;
                              dst_plain_value: ptr cdouble): bool {.cdecl.}


##  Factory identifier

let CLAP_PLUGIN_STATE_CONVERTER_FACTORY_ID*: cstring = cstring"clap.plugin-state-converter-factory/1"

##  List all the plugin state converters available in the current DSO.

type
  clap_plugin_state_converter_factory* {.bycopy.} = object
    ##  Get the number of converters.
    ##  [thread-safe]
    count*: proc (factory: ptr clap_plugin_state_converter_factory): uint32 {.cdecl.}
    ##  Retrieves a plugin state converter descriptor by its index.
    ##  Returns null in case of error.
    ##  The descriptor must not be freed.
    ##  [thread-safe]
    get_descriptor*: proc (factory: ptr clap_plugin_state_converter_factory;
                         index: uint32): ptr clap_plugin_state_converter_descriptor {.
        cdecl.}
    ##  Create a plugin state converter by its converter_id.
    ##  The returned pointer must be freed by calling converter->destroy(converter);
    ##  Returns null in case of error.
    ##  [thread-safe]
    create*: proc (factory: ptr clap_plugin_state_converter_factory;
                 converter_id: cstring): ptr clap_plugin_state_converter {.cdecl.}

