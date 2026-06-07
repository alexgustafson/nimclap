import private/std

type Id* = uint32
  ## An opaque identifier used throughout the API (ports, params, ...).
  ## A value of `invalidId` denotes "no id".

let invalidId*: Id = uint32Max
  ## Sentinel value representing an absent / invalid `Id`.
