import
  ../../plugin, ../../stringsizes

##  This extension let the plugin provide a structured way of mapping parameters to an hardware
##  controller.
##
##  This is done by providing a set of remote control pages organized by section.
##  A page contains up to 8 controls, which references parameters using param_id.
##
##  |`- [section:main]
##  |    `- [name:main] performance controls
##  |`- [section:osc]
##  |   |`- [name:osc1] osc1 page
##  |   |`- [name:osc2] osc2 page
##  |   |`- [name:osc-sync] osc sync page
##  |    `- [name:osc-noise] osc noise page
##  |`- [section:filter]
##  |   |`- [name:flt1] filter 1 page
##  |    `- [name:flt2] filter 2 page
##  |`- [section:env]
##  |   |`- [name:env1] env1 page
##  |    `- [name:env2] env2 page
##  |`- [section:lfo]
##  |   |`- [name:lfo1] env1 page
##  |    `- [name:lfo2] env2 page
##   `- etc...
##
##  One possible workflow is to have a set of buttons, which correspond to a section.
##  Pressing that button once gets you to the first page of the section.
##  Press it again to cycle through the section's pages.

let CLAP_EXT_REMOTE_CONTROLS*: UncheckedArray[char] = "clap.remote-controls.draft/2"

const
  CLAP_REMOTE_CONTROLS_COUNT* = 8

type
  clap_remote_controls_page* {.bycopy.} = object
    section_name*: array[CLAP_NAME_SIZE, char]
    page_id*: clap_id
    page_name*: array[CLAP_NAME_SIZE, char]
    param_ids*: array[CLAP_REMOTE_CONTROLS_COUNT, clap_id]
    ##  This is used to separate device pages versus preset pages.
    ##  If true, then this page is specific to this preset.
    is_for_preset*: bool

  clap_plugin_remote_controls* {.bycopy.} = object
    ##  Returns the number of pages.
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}
    ##  Get a page by index.
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; page_index: uint32;
              page: ptr clap_remote_controls_page): bool {.cdecl.}

  clap_host_remote_controls* {.bycopy.} = object
    ##  Informs the host that the remote controls have changed.
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}
    ##  Suggest a page to the host because it corresponds to what the user is currently editing in the
    ##  plugin's GUI.
    ##  [main-thread]
    suggest_page*: proc (host: ptr clap_host; page_id: clap_id) {.cdecl.}

