import
  private/macros, private/std

type
  clap_version* {.bycopy.} = object
    ##  This is the major ABI and API design
    ##  Version 0.X.Y correspond to the development stage, API and ABI are not stable
    ##  Version 1.X.Y correspond to the release stage, API and ABI are stable
    major*: uint32
    minor*: uint32
    revision*: uint32


const
  CLAP_VERSION_MAJOR* = 1
  CLAP_VERSION_MINOR* = 2
  CLAP_VERSION_REVISION* = 6
  CLAP_VERSION_INIT*: clap_version = clap_version(
    major: CLAP_VERSION_MAJOR,
    minor: CLAP_VERSION_MINOR,
    revision: CLAP_VERSION_REVISION
  )

template CLAP_VERSION_LT*(maj, min, rev: untyped): untyped =
  ((CLAP_VERSION_MAJOR < (maj)) or
      ((maj) == CLAP_VERSION_MAJOR and CLAP_VERSION_MINOR < (min)) or
      ((maj) == CLAP_VERSION_MAJOR and (min) == CLAP_VERSION_MINOR and
      CLAP_VERSION_REVISION < (rev)))

template CLAP_VERSION_EQ*(maj, min, rev: untyped): untyped =
  (((maj) == CLAP_VERSION_MAJOR) and ((min) == CLAP_VERSION_MINOR) and
      ((rev) == CLAP_VERSION_REVISION))

template CLAP_VERSION_GE*(maj, min, rev: untyped): untyped =
  (not CLAP_VERSION_LT(maj, min, rev))

let CLAP_VERSION*: clap_version = clap_version(
  major: CLAP_VERSION_MAJOR,
  minor: CLAP_VERSION_MINOR,
  revision: CLAP_VERSION_REVISION,
)


proc clap_version_is_compatible*(v: clap_version): bool {.inline, cdecl.} =
  ##  versions 0.x.y were used during development stage and aren't compatible
  return v.major >= 1
