import private/std, private/macros

##  This type defines a timestamp: the number of seconds since UNIX EPOCH.
##  See C's time_t time(time_t *).

type Timestamp* = uint64

##  Value for unknown timestamp.

let timestampUnknown*: Timestamp = 0
