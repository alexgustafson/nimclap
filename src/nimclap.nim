# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.
import std/math
import nimclap/clap/audiobuffer
import nimclap/clap/entry
import nimclap/clap/events
import nimclap/clap/host
import nimclap/clap/id
import nimclap/clap/plugin
import nimclap/clap/pluginfeatures
import nimclap/clap/process
import nimclap/clap/stream
import nimclap/clap/stringsizes
import nimclap/clap/version

import nimclap/clap/factory/pluginfactory

import nimclap/clap/ext/log
import nimclap/clap/ext/state
import nimclap/clap/ext/threadcheck
import nimclap/clap/ext/audioports
import nimclap/clap/ext/noteports
import nimclap/clap/ext/latency
import nimclap/clap/ext/params

export audiobuffer
export entry
export events
export host
export id
export plugin
export pluginfeatures
export process
export stringsizes
export stream
export version
export pluginfactory
export latency
export log
export state
export threadcheck
export audioports
export noteports
export latency
export params

proc setName*(dest: var array[nameSize, char], src: string) =
  let maxLen = min(src.len, nameSize - 1)
  for i in 0..<maxLen:
    dest[i] = src[i]
  dest[maxLen] = '\0'

# Helper for safely getting event count from input events
proc getEventCount*(events: ptr InputEvents): uint32 =
  if events.isNil: 0'u32 else: events.size(events)

# Helper for safely getting an event from input events
proc getEvent*(events: ptr InputEvents, index: uint32): ptr EventHeader =
  if events.isNil: nil else: events.get(events, index)

# Helper for safely pushing to output events
proc tryPushEvent*(events: ptr OutputEvents, event: ptr EventHeader): bool =
  if events.isNil: false else: events.tryPush(events, event)

# Helper for safely accessing audio buffer data
proc getChannelData32*(buffer: ptr AudioBuffer, channel: uint32): ptr UncheckedArray[cfloat] =
  if buffer.isNil or buffer.data32.isNil or channel >= buffer.channelCount:
    nil
  else:
    buffer.data32[channel]


# Template for safe pointer field access
template safeAccess*[T](p: ptr T, field: untyped, default: untyped): untyped =
  if p.isNil: default else: p.field


proc keyNumberToFrequency*(keyNumber: int): float =
  const A440 = 440.0
  return A440 * pow(2.0, (keyNumber.float - 69) / 12.0)

proc phaseIncrementForFrequency*(frequency: float, sampleRate: float): float =
  return

proc mixMax*(f0: float, min: float, max: float): float =
  if f0 < min: return min
  if f0 > max: return max
  return f0

proc minMax01*(f0: float): float =
  return mixMax(f0, 0.0, 1.0)
