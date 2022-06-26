## !!!Ignored construct:  ﻿ # once [NewLine] # ../plugin.h [NewLine] # ../string-sizes.h [NewLine] / @page Parameters
## / @brief parameters management
## /
## / Main idea:
## /
## / The host sees the plugin as an atomic entity; and acts as a controler on top of its parameters.
## / The plugin is responsible to keep in sync its audio processor and its GUI.
## /
## / The host can read at any time parameters value on the [main-thread] using
## / @ref clap_plugin_params.value().
## /
## / There is two options to communicate parameter value change, and they are not concurrent.
## / - send automation points during clap_plugin.process()
## / - send automation points during clap_plugin_params.flush(), this one is used when the plugin is
## /   not processing
## /
## / When the plugin changes a parameter value, it must inform the host.
## / It will send @ref CLAP_EVENT_PARAM_VALUE event during process() or flush().
## / If the user is adjusting the value, don't forget to mark the begining and end
## / of the gesture by send CLAP_EVENT_PARAM_GESTURE_BEGIN and CLAP_EVENT_PARAM_GESTURE_END events.
## /
## / @note MIDI CCs are a tricky because you may not know when the parameter adjustment ends.
## / Also if the hosts records incoming MIDI CC and parameter change automation at the same time,
## / there will be a conflict at playback: MIDI CC vs Automation.
## / The parameter automation will always target the same parameter because the param_id is stable.
## / The MIDI CC may have a different mapping in the future and may result in a different playback.
## /
## / When a MIDI CC changes a parameter's value, set the flag CLAP_EVENT_DONT_RECORD in
## / clap_event_param.header.flags. That way the host may record the MIDI CC automation, but not the
## / parameter change and there won't be conflict at playback.
## /
## / Scenarios:
## /
## / I. Loading a preset
## / - load the preset in a temporary state
## / - call @ref clap_host_params.changed() if anything changed
## / - call @ref clap_host_latency.changed() if latency changed
## / - invalidate any other info that may be cached by the host
## / - if the plugin is activated and the preset will introduce breaking change
## /   (latency, audio ports, new parameters, ...) be sure to wait for the host
## /   to deactivate the plugin to apply those changes.
## /   If there are no breaking changes, the plugin can apply them them right away.
## /   The plugin is resonsible to update both its audio processor and its gui.
## /
## / II. Turning a knob on the DAW interface
## / - the host will send an automation event to the plugin via a process() or flush()
## /
## / III. Turning a knob on the Plugin interface
## / - if the plugin is not processing, call clap_host_params->request_flush() or
## /   clap_host->request_process().
## / - send an automation event and don't forget to set begin_adjust, end_adjust and should_record
## /   flags
## / - the plugin is responsible to send the parameter value to its audio processor
## /
## / IV. Turning a knob via automation
## / - host sends an automation point during clap_plugin->process() or clap_plugin_params->flush().
## / - the plugin is responsible to update its GUI
## /
## / V. Turning a knob via plugin's internal MIDI mapping
## / - the plugin sends a CLAP_EVENT_PARAM_SET output event, set should_record to false
## / - the plugin is responsible to update its GUI
## /
## / VI. Adding or removing parameters
## / - if the plugin is activated call clap_host->restart()
## / - once the plugin isn't active:
## /   - apply the new state
## /   - if a parameter is gone or is created with an id that may have been used before,
## /     call clap_host_params.clear(host, param_id, CLAP_PARAM_CLEAR_ALL)
## /   - call clap_host_params->rescan(CLAP_PARAM_RESCAN_ALL) static const char CLAP_EXT_PARAMS [ ] = clap.params ;
## Error: expected ';'!!!

const                         ##  Is this param stepped? (integer values only)
     ##  if so the double value is converted to integer using a cast (equivalent to trunc).
  CLAP_PARAM_IS_STEPPED* = 1 shl 0 ##  Useful for for periodic parameters like a phase
  CLAP_PARAM_IS_PERIODIC* = 1 shl 1 ##  The parameter should not be shown to the user, because it is currently not used.
                               ##  It is not necessary to process automation for this parameter.
  CLAP_PARAM_IS_HIDDEN* = 1 shl 2 ##  The parameter can't be changed by the host.
  CLAP_PARAM_IS_READONLY* = 1 shl 3 ##  This parameter is used to merge the plugin and host bypass button.
                               ##  It implies that the parameter is stepped.
                               ##  min: 0 -> bypass off
                               ##  max: 1 -> bypass on
  CLAP_PARAM_IS_BYPASS* = 1 shl 4 ##  When set:
                             ##  - automation can be recorded
                             ##  - automation can be played back
                             ##
                             ##  The host can send live user changes for this parameter regardless of this flag.
                             ##
                             ##  If this parameters affect the internal processing structure of the plugin, ie: max delay, fft
                             ##  size, ... and the plugins needs to re-allocate its working buffers, then it should call
                             ##  host->request_restart(), and perform the change once the plugin is re-activated.
  CLAP_PARAM_IS_AUTOMATABLE* = 1 shl 5 ##  Does this param supports per note automations?
  CLAP_PARAM_IS_AUTOMATABLE_PER_NOTE_ID* = 1 shl 6 ##  Does this param supports per note automations?
  CLAP_PARAM_IS_AUTOMATABLE_PER_KEY* = 1 shl 7 ##  Does this param supports per channel automations?
  CLAP_PARAM_IS_AUTOMATABLE_PER_CHANNEL* = 1 shl 8 ##  Does this param supports per port automations?
  CLAP_PARAM_IS_AUTOMATABLE_PER_PORT* = 1 shl 9 ##  Does the parameter support the modulation signal?
  CLAP_PARAM_IS_MODULATABLE* = 1 shl 10 ##  Does this param supports per note automations?
  CLAP_PARAM_IS_MODULATABLE_PER_NOTE_ID* = 1 shl 11 ##  Does this param supports per note automations?
  CLAP_PARAM_IS_MODULATABLE_PER_KEY* = 1 shl 12 ##  Does this param supports per channel automations?
  CLAP_PARAM_IS_MODULATABLE_PER_CHANNEL* = 1 shl 13 ##  Does this param supports per channel automations?
  CLAP_PARAM_IS_MODULATABLE_PER_PORT* = 1 shl 14 ##  Any change to this parameter will affect the plugin output and requires to be done via
                                            ##  process() if the plugin is active.
                                            ##
                                            ##  A simple example would be a DC Offset, changing it will change the output signal and must be
                                            ##  processed.
  CLAP_PARAM_REQUIRES_PROCESS* = 1 shl 15

type
  ClapParamInfoFlags* = uint32T

##  This describes a parameter

type
  ClapParamInfoT* {.bycopy.} = object
    id*: ClapId                ##  stable parameter identifier, it must never change.
    flags*: ClapParamInfoFlags ##  This value is optional and set by the plugin.
                             ##  Its purpose is to provide a fast access to the plugin parameter:
                             ##
                             ##     Parameter *p = findParameter(param_id);
                             ##     param_info->cookie = p;
                             ##
                             ##     /* and later on */
                             ##     Parameter *p = (Parameter *)cookie;
                             ##
                             ##  It is invalidated on clap_host_params->rescan(CLAP_PARAM_RESCAN_ALL) and when the plugin is
                             ##  destroyed.
    cookie*: pointer           ##  the display name
    name*: array[clap_Name_Size, char] ##  the module path containing the param, eg:"oscillators/wt1"
                                    ##  '/' will be used as a separator to show a tree like structure.
    module*: array[clap_Path_Size, char]
    minValue*: cdouble         ##  minimum plain value
    maxValue*: cdouble         ##  maximum plain value
    defaultValue*: cdouble     ##  default plain value

  ClapPluginParamsT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT): uint32T ##  Returns the number of parameters.
                                              ##  [main-thread]
    ##  Copies the parameter's info to param_info and returns true on success.
    ##  [main-thread]
    getInfo*: proc (plugin: ptr ClapPluginT; paramIndex: uint32T;
                  paramInfo: ptr ClapParamInfoT): bool ##  Gets the parameter plain value.
                                                   ##  [main-thread]
    getValue*: proc (plugin: ptr ClapPluginT; paramId: ClapId; value: ptr cdouble): bool ##  Formats the display text for the given parameter value.
                                                                              ##  The host should always format the parameter value to text using this function
                                                                              ##  before displaying it to the user.
                                                                              ##  [main-thread]
    valueToText*: proc (plugin: ptr ClapPluginT; paramId: ClapId; value: cdouble;
                      display: cstring; size: uint32T): bool ##  Converts the display text to a parameter value.
                                                        ##  [main-thread]
    textToValue*: proc (plugin: ptr ClapPluginT; paramId: ClapId; display: cstring;
                      value: ptr cdouble): bool ##  Flushes a set of parameter changes.
                                            ##  This method must not be called concurrently to clap_plugin->process().
                                            ##  This method must not be used if the plugin is processing.
                                            ##
                                            ##  [active && !processing : audio-thread]
                                            ##  [!active : main-thread]
    flush*: proc (plugin: ptr ClapPluginT; `in`: ptr ClapInputEventsT;
                `out`: ptr ClapOutputEventsT)


const ##  The parameter values did change, eg. after loading a preset.
     ##  The host will scan all the parameters value.
     ##  The host will not record those changes as automation points.
     ##  New values takes effect immediately.
  CLAP_PARAM_RESCAN_VALUES* = 1 shl 0 ##  The value to text conversion changed, and the text needs to be rendered again.
  CLAP_PARAM_RESCAN_TEXT* = 1 shl 1 ##  The parameter info did change, use this flag for:
                               ##  - name change
                               ##  - module change
                               ##  - is_periodic (flag)
                               ##  - is_hidden (flag)
                               ##  New info takes effect immediately.
  CLAP_PARAM_RESCAN_INFO* = 1 shl 2 ##  Invalidates everything the host knows about parameters.
                               ##  It can only be used while the plugin is deactivated.
                               ##  If the plugin is activated use clap_host->restart() and delay any change until the host calls
                               ##  clap_plugin->deactivate().
                               ##
                               ##  You must use this flag if:
                               ##  - some parameters were added or removed.
                               ##  - some parameters had critical changes:
                               ##    - is_per_note (flag)
                               ##    - is_per_channel (flag)
                               ##    - is_readonly (flag)
                               ##    - is_bypass (flag)
                               ##    - is_stepped (flag)
                               ##    - is_modulatable (flag)
                               ##    - min_value
                               ##    - max_value
                               ##    - cookie
  CLAP_PARAM_RESCAN_ALL* = 1 shl 3

type
  ClapParamRescanFlags* = uint32T

const                         ##  Clears all possible references to a parameter
  CLAP_PARAM_CLEAR_ALL* = 1 shl 0 ##  Clears all automations to a parameter
  CLAP_PARAM_CLEAR_AUTOMATIONS* = 1 shl 1 ##  Clears all modulations to a parameter
  CLAP_PARAM_CLEAR_MODULATIONS* = 1 shl 2

type
  ClapParamClearFlags* = uint32T
  ClapHostParamsT* {.bycopy.} = object
    rescan*: proc (host: ptr ClapHostT; flags: ClapParamRescanFlags) ##  Rescan the full list of parameters according to the flags.
                                                              ##  [main-thread]
    ##  Clears references to a parameter.
    ##  [main-thread]
    clear*: proc (host: ptr ClapHostT; paramId: ClapId; flags: ClapParamClearFlags) ##  Request the host to call clap_plugin_params->fush().
                                                                           ##  This is useful if the plugin has parameters value changes to report to the host but the plugin
                                                                           ##  is not processing.
                                                                           ##
                                                                           ##  eg. the plugin has a USB socket to some hardware controllers and receives a parameter change
                                                                           ##  while it is not processing.
                                                                           ##
                                                                           ##  This must not be called on the [audio-thread].
                                                                           ##
                                                                           ##  [thread-safe]
    requestFlush*: proc (host: ptr ClapHostT)

