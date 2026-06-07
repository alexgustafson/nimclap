import ../id, ../events, ../host
import ../plugin, ../stringsizes

## Parameters management.
##
## Main idea:
##
## The host sees the plugin as an atomic entity; and acts as a controller on top of its parameters.
## The plugin is responsible for keeping its audio processor and its GUI in sync.
##
## The host can at any time read parameters' value on the `[main-thread]` using
## `PluginParams.getValue`.
##
## There are two options to communicate parameter value changes, and they are not concurrent.
## - send automation points during `Plugin.process`
## - send automation points during `PluginParams.flush`, for parameter changes
##   without processing audio
##
## When the plugin changes a parameter value, it must inform the host.
## It will send an `eventParamValue` event during `process` or `flush`.
## If the user is adjusting the value, don't forget to mark the beginning and end
## of the gesture by sending `eventParamGestureBegin` and `eventParamGestureEnd`
## events.
##
## Note: MIDI CCs are tricky because you may not know when the parameter adjustment ends.
## Also if the host records incoming MIDI CC and parameter change automation at the same time,
## there will be a conflict at playback: MIDI CC vs Automation.
## The parameter automation will always target the same parameter because the param_id is stable.
## The MIDI CC may have a different mapping in the future and may result in a different playback.
##
## When a MIDI CC changes a parameter's value, set the flag `dontRecord` in
## `EventParamValue.header.flags`. That way the host may record the MIDI CC automation, but not the
## parameter change and there won't be conflict at playback.
##
## Scenarios:
##
## **I. Loading a preset**
##
## - load the preset in a temporary state
## - call `HostParams.rescan` if anything changed
## - call `HostLatency.changed` if latency changed
## - invalidate any other info that may be cached by the host
## - if the plugin is activated and the preset will introduce breaking changes
##   (latency, audio ports, new parameters, ...) be sure to wait for the host
##   to deactivate the plugin to apply those changes.
##   If there are no breaking changes, the plugin can apply them them right away.
##   The plugin is responsible for updating both its audio processor and its gui.
##
## **II. Turning a knob on the DAW interface**
##
## - the host will send an automation event to the plugin via a `process` or `flush`
##
## **III. Turning a knob on the Plugin interface**
##
## - the plugin is responsible for sending the parameter value to its audio processor
## - call `HostParams.requestFlush` or `Host.requestProcess`.
## - when the host calls either `Plugin.process` or `PluginParams.flush`,
##   send an automation event and don't forget to wrap the parameter change(s)
##   with `eventParamGestureBegin` and `eventParamGestureEnd` to define the
##   beginning and end of the gesture.
##
## **IV. Turning a knob via automation**
##
## - host sends an automation point during `Plugin.process` or `PluginParams.flush`.
## - the plugin is responsible for updating its GUI
##
## **V. Turning a knob via plugin's internal MIDI mapping**
##
## - the plugin sends an `eventParamValue` output event, set should_record to false
## - the plugin is responsible for updating its GUI
##
## **VI. Adding or removing parameters**
##
## - if the plugin is activated call `Host.requestRestart`
## - once the plugin isn't active:
##   - apply the new state
##   - if a parameter is gone or is created with an id that may have been used before,
##     call `HostParams.clear(host, paramId, paramClearAll)`
##   - call `HostParams.rescan(paramRescanAll)`
##
## CLAP allows the plugin to change the parameter range, yet the plugin developer
## should be aware that doing so isn't without risk, especially if you made the
## promise to never change the sound. If you want to be 100% certain that the
## sound will not change with all host, then simply never change the range.
##
## There are two approaches to automations, either you automate the plain value,
## or you automate the knob position. The first option will be robust to a range
## increase, while the second won't be.
##
## If the host goes with the second approach (automating the knob position), it means
## that the plugin is hosted in a relaxed environment regarding sound changes (they are
## accepted, and not a concern as long as they are reasonable). Though, stepped parameters
## should be stored as plain value in the document.
##
## If the host goes with the first approach, there will still be situation where the
## sound may inevitably change. For example, if the plugin increase the range, there
## is an automation playing at the max value and on top of that an LFO is applied.
## See the following curve:
##                                    .
##                                   . .
##           .....                  .   .
##  before: .     .     and after: .     .
##
## Persisting parameter values:
##
## Plugins are responsible for persisting their parameter's values between
## sessions by implementing the state extension. Otherwise parameter value will
## not be recalled when reloading a project. Hosts should *not* try to save and
## restore parameter values for plugins that don't implement the state
## extension.
##
## Advice for the host:
##
## - store plain values in the document (automation)
## - store modulation amount in plain value delta, not in percentage
## - when you apply a CC mapping, remember the min/max plain values so you can adjust
## - do not implement a parameter saving fall back for plugins that don't
##   implement the state extension
##
## Advice for the plugin:
##
## - think carefully about your parameter range when designing your DSP
## - avoid shrinking parameter ranges, they are very likely to change the sound
## - consider changing the parameter range as a tradeoff: what you improve vs what you break
## - make sure to implement saving and loading the parameter values using the
##   state extension
## - if you plan to use adapters for other plugin formats, then you need to pay extra
##   attention to the adapter requirements

let extParams*: cstring = cstring"clap.params"

const
  paramIsStepped* = 1 shl 0
    ## Is this param stepped? (integer values only)
    ## If so the double value is converted to integer using a cast (equivalent to trunc).
  paramIsPeriodic* = 1 shl 1
    ## Useful for periodic parameters like a phase.
  paramIsHidden* = 1 shl 2
    ## The parameter should not be shown to the user, because it is currently not used.
    ## It is not necessary to process automation for this parameter.
  paramIsReadonly* = 1 shl 3
    ## The parameter can't be changed by the host.
  paramIsBypass* = 1 shl 4
    ## This parameter is used to merge the plugin and host bypass button.
    ## It implies that the parameter is stepped.
    ## min: 0 -> bypass off
    ## max: 1 -> bypass on
  paramIsAutomatable* = 1 shl 5
    ## When set:
    ## - automation can be recorded
    ## - automation can be played back
    ##
    ## The host can send live user changes for this parameter regardless of this flag.
    ##
    ## If this parameter affects the internal processing structure of the plugin, ie: max delay, fft
    ## size, ... and the plugins needs to re-allocate its working buffers, then it should call
    ## `Host.requestRestart`, and perform the change once the plugin is re-activated.
  paramIsAutomatablePerNoteId* = 1 shl 6
    ## Does this parameter support per note automations?
  paramIsAutomatablePerKey* = 1 shl 7
    ## Does this parameter support per key automations?
  paramIsAutomatablePerChannel* = 1 shl 8
    ## Does this parameter support per channel automations?
  paramIsAutomatablePerPort* = 1 shl 9
    ## Does this parameter support per port automations?
  paramIsModulatable* = 1 shl 10
    ## Does this parameter support the modulation signal?
  paramIsModulatablePerNoteId* = 1 shl 11
    ## Does this parameter support per note modulations?
  paramIsModulatablePerKey* = 1 shl 12
    ## Does this parameter support per key modulations?
  paramIsModulatablePerChannel* = 1 shl 13
    ## Does this parameter support per channel modulations?
  paramIsModulatablePerPort* = 1 shl 14
    ## Does this parameter support per port modulations?
  paramRequiresProcess* = 1 shl 15
    ## Any change to this parameter will affect the plugin output and requires to be done via
    ## `Plugin.process` if the plugin is active.
    ##
    ## A simple example would be a DC Offset, changing it will change the output signal and must be
    ## processed.
  paramIsEnum* = 1 shl 16
    ## This parameter represents an enumerated value.
    ## If you set this flag, then you must set `paramIsStepped` too.
    ## All values from min to max must not have a blank `valueToText`.

type ParamInfoFlags* = uint32

type
  ParamInfo* {.bycopy.} = object
    ## This describes a parameter.
    id*: Id
      ## Stable parameter identifier, it must never change.
    flags*: ParamInfoFlags
    cookie*: pointer
      ## This value is optional and set by the plugin.
      ## Its purpose is to provide fast access to the plugin parameter object by caching its pointer.
      ## For instance:
      ##
      ## in `PluginParams.getInfo`:
      ##    Parameter *p = findParameter(param_id);
      ##    param_info->cookie = p;
      ##
      ## later, in `Plugin.process`:
      ##
      ##    Parameter *p = (Parameter *)event->cookie;
      ##    if (!p) [[unlikely]]
      ##       p = findParameter(event->param_id);
      ##
      ## where findParameter() is a function the plugin implements to map parameter ids to internal
      ## objects.
      ##
      ## Important:
      ##  - The cookie is invalidated by a call to `HostParams.rescan(paramRescanAll)` or
      ##    when the plugin is destroyed.
      ##  - The host will either provide the cookie as issued or nullptr in events addressing
      ##    parameters.
      ##  - The plugin must gracefully handle the case of a cookie which is nullptr.
      ##  - Many plugins will process the parameter events more quickly if the host can provide the
      ##    cookie in a faster time than a hashmap lookup per param per event.
    name*: array[name_Size, char]
      ## The display name. eg: "Volume". This does not need to be unique. Do not include the module
      ## text in this. The host should concatenate/format the module + name in the case where showing
      ## the name alone would be too vague.
    module*: array[path_Size, char]
      ## The module path containing the param, eg: "Oscillators/Wavetable 1".
      ## '/' will be used as a separator to show a tree-like structure.
    minValue*: cdouble
      ## Minimum plain value. Must be finite (`std::isfinite` true)
    maxValue*: cdouble
      ## Maximum plain value. Must be finite
    defaultValue*: cdouble
      ## Default plain value. Must be in [min, max] range.

  PluginParams* {.bycopy.} = object
    count*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Returns the number of parameters.
      ## `[main-thread]`
    getInfo*: proc(
      plugin: ptr Plugin, paramIndex: uint32, paramInfo: ptr ParamInfo
    ): bool {.cdecl.}
      ## Copies the parameter's info to `paramInfo`.
      ## Returns true on success.
      ## `[main-thread]`
    getValue*:
      proc(plugin: ptr Plugin, paramId: Id, outValue: ptr cdouble): bool {.cdecl.}
      ## Writes the parameter's current value to `outValue`.
      ## Returns true on success.
      ## `[main-thread]`
    valueToText*: proc(
      plugin: ptr Plugin,
      paramId: Id,
      value: cdouble,
      outBuffer: cstring,
      outBufferCapacity: uint32,
    ): bool {.cdecl.}
      ## Fills `outBuffer` with a null-terminated UTF-8 string that represents the parameter at the
      ## given `value` argument. eg: "2.3 kHz". The host should always use this to format parameter
      ## values before displaying it to the user.
      ## Returns true on success.
      ## `[main-thread]`
    textToValue*: proc(
      plugin: ptr Plugin, paramId: Id, paramValueText: cstring, outValue: ptr cdouble
    ): bool {.cdecl.}
      ## Converts the null-terminated UTF-8 `paramValueText` into a double and writes it to
      ## `outValue`. The host can use this to convert user input into a parameter value.
      ## Returns true on success.
      ## `[main-thread]`
    flush*:
      proc(plugin: ptr Plugin, `in`: ptr InputEvents, `out`: ptr OutputEvents) {.cdecl.}
      ## Flushes a set of parameter changes.
      ## This method must not be called concurrently to `Plugin.process`.
      ##
      ## Note: if the plugin is processing, then the `process` call will already achieve the
      ## parameter update (bi-directional), so a call to flush isn't required, also be aware
      ## that the plugin may use the sample offset in `process`, while this information would be
      ## lost within flush.
      ##
      ## `[active ? audio-thread : main-thread]`

const
  paramRescanValues* = 1 shl 0
    ## The parameter values did change, eg. after loading a preset.
    ## The host will scan all the parameters value.
    ## The host will not record those changes as automation points.
    ## New values takes effect immediately.
  paramRescanText* = 1 shl 1
    ## The value to text conversion changed, and the text needs to be rendered again.
  paramRescanInfo* = 1 shl 2
    ## The parameter info did change, use this flag for:
    ## - name change
    ## - module change
    ## - is_periodic (flag)
    ## - is_hidden (flag)
    ## New info takes effect immediately.
  paramRescanAll* = 1 shl 3
    ## Invalidates everything the host knows about parameters.
    ## It can only be used while the plugin is deactivated.
    ## If the plugin is activated use `Host.requestRestart` and delay any change until the host calls
    ## `Plugin.deactivate`.
    ##
    ## You must use this flag if:
    ## - some parameters were added or removed.
    ## - some parameters had critical changes:
    ##   - is_per_note (flag)
    ##   - is_per_key (flag)
    ##   - is_per_channel (flag)
    ##   - is_per_port (flag)
    ##   - is_readonly (flag)
    ##   - is_bypass (flag)
    ##   - is_stepped (flag)
    ##   - is_modulatable (flag)
    ##   - min_value
    ##   - max_value
    ##   - cookie

type ParamRescanFlags* = uint32

const
  paramClearAll* = 1 shl 0
    ## Clears all possible references to a parameter
  paramClearAutomations* = 1 shl 1
    ## Clears all automations to a parameter
  paramClearModulations* = 1 shl 2
    ## Clears all modulations to a parameter

type
  ParamClearFlags* = uint32
  HostParams* {.bycopy.} = object
    rescan*: proc(host: ptr Host, flags: ParamRescanFlags) {.cdecl.}
      ## Rescan the full list of parameters according to the flags.
      ## `[main-thread]`
    clear*: proc(host: ptr Host, paramId: Id, flags: ParamClearFlags) {.cdecl.}
      ## Clears references to a parameter.
      ## `[main-thread]`
    requestFlush*: proc(host: ptr Host) {.cdecl.}
      ## Request a parameter flush.
      ##
      ## The host will then schedule a call to either:
      ## - `Plugin.process`
      ## - `PluginParams.flush`
      ##
      ## This function is always safe to use and should not be called from an `[audio-thread]` as the
      ## plugin would already be within `process` or `flush`.
      ##
      ## `[thread-safe,!audio-thread]`
