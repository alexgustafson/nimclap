import
  private/std, private/macros

##  We use fixed point representation of beat time and seconds time
##  Usage:
##    double x = ...; // in beats
##    clap_beattime y = round(CLAP_BEATTIME_FACTOR * x);
##  This will never change

let CLAP_BEATTIME_FACTOR*: int64 = 1'i64 shl 31

let CLAP_SECTIME_FACTOR*: int64 = 1'i64 shl 31

type
  clap_beattime* = int64
  clap_sectime* = int64
