import private/macros, private/std

type Version* {.bycopy.} = object
  ##  This is the major ABI and API design
  ##  Version 0.X.Y correspond to the development stage, API and ABI are not stable
  ##  Version 1.X.Y correspond to the release stage, API and ABI are stable
  major*: uint32
  minor*: uint32
  revision*: uint32

const
  versionMajor* = 1
  versionMinor* = 2
  versionRevision* = 6
  versionInit* = Version(
    major: versionMajor,
    minor: versionMinor,
    revision: versionRevision,
  )

template versionLt*(maj, min, rev: untyped): untyped =
  (
    (versionMajor < (maj)) or ((maj) == versionMajor and versionMinor < (min)) or
    ((maj) == versionMajor and (min) == versionMinor and versionRevision < (rev))
  )

template versionEq*(maj, min, rev: untyped): untyped =
  (
    ((maj) == versionMajor) and ((min) == versionMinor) and (
      (rev) == versionRevision
    )
  )

template versionGe*(maj, min, rev: untyped): untyped =
  (not versionLt(maj, min, rev))

let version*: Version = versionInit

proc versionIsCompatible*(v: Version): bool {.inline, cdecl.} =
  ##  versions 0.x.y were used during development stage and aren't compatible
  return v.major >= 1
