import private/std, private/macros

##  We use fixed point representation of beat time and seconds time
##  Usage:
##    double x = ...; // in beats
##    clap_beattime y = round(CLAP_BEATTIME_FACTOR * x);
##  This will never change

let beattimeFactor*: int64 = 1'i64 shl 31

let sectimeFactor*: int64 = 1'i64 shl 31

type
  Beattime* = int64
  Sectime* = int64
