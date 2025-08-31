import private/std

type Color* {.bycopy.} = object
  alpha*: uint8
  red*: uint8
  green*: uint8
  blue*: uint8

let colorTransparent*: Color = Color(alpha: 0, red: 0, green: 0, blue: 0)
