import ../../plugin

## This extension allows a host to communicate to a plugin the octave number
## associated with MIDI Note 60 (aka "Middle C").
## Since various hosts and standards call note 60 either C3, C4 or C5, host
## displays and plugin displays often mismatch absent this information being
## shared.

let extOctaveNumber*: cstring = cstring"clap.octave-number/1"

type PluginOctaveNumber* {.bycopy.} = object
  setNote60Octave*: proc(plugin: ptr Plugin, octaveNumber: int8) {.cdecl.}
    ## If displaying the name of a note, and using standard CDEFGAB scale note
    ## names on a piano-roll-like display, this api will tell the plugin which
    ## octave number is associated with note 60. For instance, calling this with
    ## `3` would indicate to the plugin that the consistent name for note 60 is
    ## "C3", for 72 is "C4" etc... if using CDEFGAB note names across a 12 note
    ## display.
    ## `[main-thread]`
