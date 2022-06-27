import
  private/macros, private/std

type
  ClapVersionT* {.bycopy.} = object
    major*: uint32T ##  This is the major ABI and API design
                  ##  Version 0.X.Y correspond to the development stage, API and ABI are not stable
                  ##  Version 1.X.Y correspont to the release stage, API and ABI are stable
    minor*: uint32T
    revision*: uint32T


const
  CLAP_VERSION_MAJOR* = (cast[uint32T](1))
  CLAP_VERSION_MINOR* = (cast[uint32T](0))
  CLAP_VERSION_REVISION* = (cast[uint32T](2))
  CLAP_VERSION_INIT* = (
    CLAP_VERSION_MAJOR,
    CLAP_VERSION_MINOR,
    CLAP_VERSION_REVISION
  )

var CLAP_VERSION*: ClapVersionT = cast[ClapVersionT](CLAP_VERSION_INIT)

## !!!Ignored construct:  CLAP_NODISCARD static inline bool clap_version_is_compatible ( const clap_version_t v ) {  versions 0.x.y were used during development stage and aren't compatible return v . major >= 1 ; }
## Error: token expected: ; but got: [identifier]!!!
