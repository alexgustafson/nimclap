import
  private/std, private/macros

## / We use fixed point representation of beat time and seconds time
## / Usage:
## /   double x = ...; // in beats
## /   clap_beattime y = round(CLAP_BEATTIME_FACTOR * x);
##  This will never change

var CLAP_BEATTIME_FACTOR*: int64T = 1LL'i64 shl 31

var CLAP_SECTIME_FACTOR*: int64T = 1LL'i64 shl 31

type
  ClapBeattime* = int64T
  ClapSectime* = int64T
