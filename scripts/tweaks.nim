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
  replace_strings* = @[
    (version_text, version_replace),
    (unchecked_array_char, unchecked_array_char_replace),
  ]

  additional_imports* = {
    "plugin": "import version\n",
    "pluginfactory": "import host\n",
    "latency": "import ../host\n",
    "log": "import ../host\n",
    "threadcheck": "import ../host\n",
    "noteports": "import ../id, ../host\n",
    "audioports": "import ../id, ../host\n",
    "state": "import ../host\n",
  }.toTable
