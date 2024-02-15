import
  private/std, private/macros

##  This type defines a timestamp: the number of seconds since UNIX EPOCH.
##  See C's time_t time(time_t *).

type
  clap_timestamp* = uint64

##  Value for unknown timestamp.

let CLAP_TIMESTAMP_UNKNOWN*: clap_timestamp = 0
