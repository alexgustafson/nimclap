import
  params, ../color

##  This extension lets the host tell the plugin to display a little color based indication on the
##  parameter. This can be used to indicate:
##  - a physical controller is mapped to a parameter
##  - the parameter is current playing an automation
##  - the parameter is overriding the automation
##  - etc...
##
##  The color semantic depends upon the host here and the goal is to have a consistent experience
##  across all plugins.

let CLAP_EXT_PARAM_INDICATION*: cstring = cstring"clap.param-indication/4"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let CLAP_EXT_PARAM_INDICATION_COMPAT*: cstring = cstring"clap.param-indication.draft/4"

const                         ##  The host doesn't have an automation for this parameter
  CLAP_PARAM_INDICATION_AUTOMATION_NONE* = 0 ##  The host has an automation for this parameter, but it isn't playing it
  CLAP_PARAM_INDICATION_AUTOMATION_PRESENT* = 1 ##  The host is playing an automation for this parameter
  CLAP_PARAM_INDICATION_AUTOMATION_PLAYING* = 2 ##  The host is recording an automation on this parameter
  CLAP_PARAM_INDICATION_AUTOMATION_RECORDING* = 3 ##  The host should play an automation for this parameter, but the user has started to adjust this
                                               ##  parameter and is overriding the automation playback
  CLAP_PARAM_INDICATION_AUTOMATION_OVERRIDING* = 4

type
  clap_plugin_param_indication* {.bycopy.} = object
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
    set_mapping*: proc (plugin: ptr clap_plugin; param_id: clap_id; has_mapping: bool;
                      color: ptr clap_color; label: cstring; description: cstring) {.
        cdecl.}
    ##  Sets or clears an automation indication.
    ##
    ##  automation_state: current automation state for the given parameter
    ##  color: if set, the color to use to display the automation indication in the plugin GUI
    ##
    ##  Parameter indications should not be saved in the plugin context, and are off by default.
    ##  [main-thread]
    set_automation*: proc (plugin: ptr clap_plugin; param_id: clap_id;
                         automation_state: uint32; color: ptr clap_color) {.cdecl.}

