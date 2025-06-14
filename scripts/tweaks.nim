import std/tables


const
  privateStd* = """
type
    uint8T*  = uint8
    uint16T* = uint16
    uint32T* = uint32
    uint64T* = uint64
    int8T*   = int8
    int16T*  = int16
    int32T*  = int32
    int64T*  = int64

const
  uint32Max* = uint32.high
  UINT32_MAX* = uint32.high
"""
  privateMacros* = """
type
    placeholder*  = uint8
"""
  version_text: string = "let CLAP_VERSION*: clap_version = CLAP_VERSION_INIT"
  version_replace: string = """
let CLAP_VERSION*: clap_version = clap_version(
  major: CLAP_VERSION_MAJOR,
  minor: CLAP_VERSION_MINOR,
  revision: CLAP_VERSION_REVISION,
)
"""
  unchecked_array_char: string = "UncheckedArray[char] = "
  unchecked_array_char_replace: string = "cstring = cstring"
  audio_buffer_32: string = "data32*: ptr ptr cfloat"
  audio_buffer_32_replace: string = "data32*: ptr UncheckedArray[UncheckedArray[cfloat]]"
  audio_buffer_64: string = "data64*: ptr ptr cdouble"
  audio_buffer_64_replace: string = "data64*: ptr UncheckedArray[UncheckedArray[cdouble]]"
  audio_process_inputs: string = "audio_inputs*: ptr clap_audio_buffer"
  audio_process_inputs_replace: string = "audio_inputs*: ptr UncheckedArray[clap_audio_buffer]"
  audio_process_outputs: string = "audio_outputs*: ptr clap_audio_buffer"
  audio_process_outputs_replace: string = "audio_outputs*: ptr UncheckedArray[clap_audio_buffer]"
  entry_clap_entry: string = "let clap_entry*: clap_plugin_entry"
  entry_clap_entry_replace: string = ""
  version_init: string = """
  CLAP_VERSION_INIT* = (cast[uint32](CLAP_VERSION_MAJOR),
    cast[uint32](CLAP_VERSION_MINOR), cast[uint32](CLAP_VERSION_REVISION))
"""
  version_init_replace: string = """
  CLAP_VERSION_INIT*: clap_version = clap_version(
    major: CLAP_VERSION_MAJOR,
    minor: CLAP_VERSION_MINOR,
    revision: CLAP_VERSION_REVISION
  )
"""

  replace_strings* = @[
    (version_text, version_replace),
    (unchecked_array_char, unchecked_array_char_replace),
    (audio_buffer_32, audio_buffer_32_replace),
    (audio_buffer_64, audio_buffer_64_replace),
    (audio_process_inputs, audio_process_inputs_replace),
    (audio_process_outputs, audio_process_outputs_replace),
    (entry_clap_entry, entry_clap_entry_replace),
    (version_init, version_init_replace),
  ]

  additional_imports* = {
    "plugin": "import version\n",
    "pluginfactory": "import ../host\n",
    "latency": "import ../host\n",
    "log": "import ../host\n",
    "threadcheck": "import ../host\n",
    "noteports": "import ../id, ../host\n",
    "audioports": "import ../id, ../host\n",
    "state": "import ../host\n",
  }.toTable
