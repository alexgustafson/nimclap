import
  private/std, private/macros

type
  ClapIstreamT* {.bycopy.} = object
    ctx*: pointer              ##  reserved pointer for the stream
                ##  returns the number of bytes read; 0 indicates end of file and -1 a read error
    read*: proc (stream: ptr ClapIstream; buffer: pointer; size: uint64T): int64T

  ClapOstreamT* {.bycopy.} = object
    ctx*: pointer              ##  reserved pointer for the stream
                ##  returns the number of bytes written; -1 on write error
    write*: proc (stream: ptr ClapOstream; buffer: pointer; size: uint64T): int64T

