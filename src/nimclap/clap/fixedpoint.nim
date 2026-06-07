let beattimeFactor*: int64 = 1'i64 shl 31
  ## We use fixed point representation of beat time and seconds time.
  ## Usage:
  ##   let x = ...        # in beats
  ##   let y = round(beattimeFactor.float * x)
  ## This will never change.

let sectimeFactor*: int64 = 1'i64 shl 31

type
  Beattime* = int64
  Sectime* = int64
