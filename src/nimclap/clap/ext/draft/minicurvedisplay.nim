import ../../plugin, ../../host

## This extension allows a host to render a small curve provided by the plugin.
## A useful application is to render an EQ frequency response in the DAW mixer view.

let extMiniCurveDisplay*: cstring = cstring"clap.mini-curve-display/3"

type MiniCurveDisplayCurveKind* {.pure.} = enum
  curveDisplayCurveKindUnspecified = 0
    ## If the curve's kind doesn't fit in any proposed kind, use this one
    ## and perhaps, make a pull request to extend the list.
  curveDisplayCurveKindGainResponse = 1
    ## The mini curve is intended to draw the total gain response of the plugin.
    ## In this case the y values are in dB and the x values are in Hz (logarithmic).
    ## This would be useful in for example an equalizer.
  curveDisplayCurveKindPhaseResponse = 2
    ## The mini curve is intended to draw the total phase response of the plugin.
    ## In this case the y values are in radians and the x values are in Hz (logarithmic).
    ## This would be useful in for example an equalizer.
  curveDisplayCurveKindTransferCurve = 3
    ## The mini curve is intended to draw the transfer curve of the plugin.
    ## In this case the both x and y values are in dB.
    ## This would be useful in for example a compressor or distortion plugin.
  curveDisplayCurveKindGainReduction = 4
    ## This mini curve is intended to draw gain reduction over time. In this case
    ## x refers to the window in seconds and y refers to level in dB, `xMin` is
    ## always 0, and `xMax` would be the duration of the window.
    ## This would be useful in for example a compressor or limiter.
  curveDisplayCurveKindTimeSeries = 5
    ## This curve is intended as a generic time series plot. In this case
    ## x refers to the window in seconds. `xMin` is always 0, and `xMax` would be the duration of the
    ## window.
    ## Y is not specified and up to the plugin.
    ##
    ## Note: more entries could be added here in the future

type MiniCurveDisplayCurveHints* {.bycopy.} = object
  xMin*: cdouble
    ## Range for the x axis.
  xMax*: cdouble
  yMin*: cdouble
    ## Range for the y axis.
  yMax*: cdouble

type
  MiniCurveDisplayCurveData* {.bycopy.} = object
    ## A set of points representing the curve to be painted.
    curveKind*: int32
      ## Indicates the kind of curve those values represent, the host can use this
      ## information to paint the curve using a meaningful color.
    values*: ptr uint16
      ## `values[0]` will be the leftmost value and `values[dataSize - 1]` will be the rightmost
      ## value.
      ##
      ## The value 0 and `UINT16_MAX` won't be painted.
      ## The value 1 will be at the bottom of the curve and `UINT16_MAX - 1` will be at the top.
    valuesCount*: uint32

  PluginMiniCurveDisplay* {.bycopy.} = object
    getCurveCount*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Returns the number of curves the plugin wants to paint.
      ## Be aware that the space to display those curves will be small, and too much data will make
      ## the output hard to read.
    render*: proc(
      plugin: ptr Plugin, curves: ptr MiniCurveDisplayCurveData, curvesSize: uint32
    ): uint32 {.cdecl.}
      ## Renders the curve into each the curves buffer.
      ##
      ## curves is an array, and each entries (up to `curvesSize`) contains pre-allocated
      ## values buffer that must be filled by the plugin.
      ##
      ## The host will "stack" the curves, from the first one to the last one.
      ## `curves[0]` is the first curve to be painted.
      ## `curves[n + 1]` will be painted over `curves[n]`.
      ##
      ## Returns the number of curves rendered.
      ## `[main-thread]`
    setObserved*: proc(plugin: ptr Plugin, isObserved: bool) {.cdecl.}
      ## Tells the plugin if the curve is currently observed or not.
      ## When it isn't observed `render` can't be called.
      ##
      ## When `isObserved` becomes true, the curve content and axis name are implicitly invalidated. So
      ## the plugin don't need to call `Host.changed`.
      ##
      ## `[main-thread]`
    getAxisName*: proc(
      plugin: ptr Plugin,
      curveIndex: uint32,
      xName: cstring,
      yName: cstring,
      nameCapacity: uint32,
    ): bool {.cdecl.}
      ## Retrives the axis name.
      ## `xName` and `yName` must not to be null.
      ## Returns true on success, if the name capacity was sufficient.
      ## `[main-thread]`

  minicurvedisplaychangeflags* = enum
    curveDisplayCurveChanged = 1 shl 0
      ## Informs the host that the curve content changed.
      ## Can only be called if the curve is observed and is static.
    curveDisplayAxisNameChanged = 1 shl 1
      ## Informs the host that the curve axis name changed.
      ## Can only be called if the curve is observed.

type HostMiniCurveDisplay* {.bycopy.} = object
  getHints*: proc(
    host: ptr Host, kind: uint32, hints: ptr MiniCurveDisplayCurveHints
  ): bool {.cdecl.}
    ## Fills in the given `MiniCurveDisplayCurveHints` structure and returns
    ## true if successful. If not, return false.
    ## `[main-thread]`
  setDynamic*: proc(host: ptr Host, isDynamic: bool) {.cdecl.}
    ## Mark the curve as being static or dynamic.
    ## The curve is initially considered as static, though the plugin should explicitely
    ## initialize this state.
    ##
    ## When static, the curve changes will be notified by calling `Host.changed`.
    ## When dynamic, the curve is constantly changing and the host is expected to
    ## periodically re-render.
    ##
    ## `[main-thread]`
  changed*: proc(host: ptr Host, flags: uint32) {.cdecl.}
    ## See `minicurvedisplaychangeflags`.
    ## `[main-thread]`
