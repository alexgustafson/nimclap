import private/std, private/macros

type Timestamp* = uint64
  ## This type defines a timestamp: the number of seconds since UNIX EPOCH.
  ## See C's `time_t time(time_t *)`.

let timestampUnknown*: Timestamp = 0
  ## Value for unknown timestamp.
