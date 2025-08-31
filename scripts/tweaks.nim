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
"""
  privateMacros* = """
type
    placeholder*  = uint8
"""
  version_text: string = "let VERSION*: Version = versionInit"
  version_replace: string = "let version*: Version = versionInit"
  unchecked_array_char: string = "UncheckedArray[char] = "
  unchecked_array_char_replace: string = "cstring = cstring"
  audio_buffer_32: string = "data32*: ptr ptr cfloat"
  audio_buffer_32_replace: string = "data32*: ptr UncheckedArray[ptr UncheckedArray[cfloat]]"
  audio_buffer_64: string = "data64*: ptr ptr cdouble"
  audio_buffer_64_replace: string = "data64*:  ptr UncheckedArray[ptr UncheckedArray[cdouble]]"
  audio_process_inputs: string = "audioInputs*: ptr AudioBuffer"
  audio_process_inputs_replace: string = "audioInputs*: ptr UncheckedArray[AudioBuffer]"
  audio_process_outputs: string = "audioOutputs*: ptr AudioBuffer"
  audio_process_outputs_replace: string = "audioOutputs*: ptr UncheckedArray[AudioBuffer]"
  entry_clap_entry: string = "let entry*: PluginEntry"
  entry_clap_entry_replace: string = ""
  host_clapversion_entry: string = "  version*: Version"
  host_clapversion_entry_replace: string = "  clapVersion*: Version"
  version_init: string = """versionInit* = (
    cast[uint32](versionMajor),
    cast[uint32](versionMinor),
    cast[uint32](versionRevision),
  )"""
  version_init_replace: string = """versionInit* = Version(
    major: versionMajor,
    minor: versionMinor,
    revision: versionRevision,
  )"""

  replace_strings* = @[
    (version_text, version_replace),
    (unchecked_array_char, unchecked_array_char_replace),
    (audio_buffer_32, audio_buffer_32_replace),
    (audio_buffer_64, audio_buffer_64_replace),
    (audio_process_inputs, audio_process_inputs_replace),
    (audio_process_outputs, audio_process_outputs_replace),
    (entry_clap_entry, entry_clap_entry_replace),
    (version_init, version_init_replace),
    (host_clapversion_entry, host_clapversion_entry_replace),
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
    "params": "import../id, ../events, ../host\n",
  }.toTable
