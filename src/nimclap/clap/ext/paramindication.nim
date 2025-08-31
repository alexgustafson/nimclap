import params, ../color

##  This extension lets the host tell the plugin to display a little color based indication on the
##  parameter. This can be used to indicate:
##  - a physical controller is mapped to a parameter
##  - the parameter is current playing an automation
##  - the parameter is overriding the automation
##  - etc...
##
##  The color semantic depends upon the host here and the goal is to have a consistent experience
##  across all plugins.

let extParamIndication*: cstring = cstring"clap.param-indication/4"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let extParamIndicationCompat*: cstring = cstring"clap.param-indication.draft/4"

const ##  The host doesn't have an automation for this parameter
  paramIndicationAutomationNone* = 0
    ##  The host has an automation for this parameter, but it isn't playing it
  paramIndicationAutomationPresent* = 1
    ##  The host is playing an automation for this parameter
  paramIndicationAutomationPlaying* = 2
    ##  The host is recording an automation on this parameter
  paramIndicationAutomationRecording* = 3
    ##  The host should play an automation for this parameter, but the user has started to adjust this
    ##  parameter and is overriding the automation playback
  paramIndicationAutomationOverriding* = 4

type PluginParamIndication* {.bycopy.} = object
  ##  Sets or clears a mapping indication.
  ##
  ##  has_mapping: does the parameter currently has a mapping?
  ##  color: if set, the color to use to highlight the control in the plugin GUI
  ##  label: if set, a small string to display on top of the knob which identifies the hardware
  ##  controller description: if set, a string which can be used in a tooltip, which describes the
  ##  current mapping
  ##
  ##  Parameter indications should not be saved in the plugin context, and are off by default.
  ##  [main-thread]
  setMapping*: proc(
    plugin: ptr Plugin,
    paramId: Id,
    hasMapping: bool,
    color: ptr Color,
    label: cstring,
    description: cstring,
  ) {.cdecl.}
  ##  Sets or clears an automation indication.
  ##
  ##  automation_state: current automation state for the given parameter
  ##  color: if set, the color to use to display the automation indication in the plugin GUI
  ##
  ##  Parameter indications should not be saved in the plugin context, and are off by default.
  ##  [main-thread]
  setAutomation*: proc(
    plugin: ptr Plugin, paramId: Id, automationState: uint32, color: ptr Color
  ) {.cdecl.}
