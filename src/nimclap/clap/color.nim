import
  private/std

type
  clap_color* {.bycopy.} = object
    alpha*: uint8
    red*: uint8
    green*: uint8
    blue*: uint8


let CLAP_COLOR_TRANSPARENT*: clap_color = clap_color(alpha: 0, red: 0, green: 0, blue: 0)
