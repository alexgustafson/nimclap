import
  private/std, private/macros

##  @page Streams
##
##  ## Notes on using streams
##
##  When working with `clap_istream` and `clap_ostream` objects to load and save
##  state, it is important to keep in mind that the host may limit the number of
##  bytes that can be read or written at a time. The return values for the
##  stream read and write functions indicate how many bytes were actually read
##  or written. You need to use a loop to ensure that you read or write the
##  entirety of your state. Don't forget to also consider the negative return
##  values for the end of file and IO error codes.

type
  clap_istream* {.bycopy.} = object
    ctx*: pointer
    ##  reserved pointer for the stream
    ##  returns the number of bytes read; 0 indicates end of file and -1 a read error
    read*: proc (stream: ptr clap_istream; buffer: pointer; size: uint64): int64 {.cdecl.}

  clap_ostream* {.bycopy.} = object
    ctx*: pointer
    ##  reserved pointer for the stream
    ##  returns the number of bytes written; -1 on write error
    write*: proc (stream: ptr clap_ostream; buffer: pointer; size: uint64): int64 {.cdecl.}

