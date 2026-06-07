import ../plugin, ../stringsizes, ../id, ../host

## This extension let the plugin provide a structured way of mapping parameters to a hardware
## controller.
##
## This is done by providing a set of remote control pages organized by section.
## A page contains up to 8 controls, which references parameters using `param_id`.
##
## |`- [section:main]
## |    `- [name:main] performance controls
## |`- [section:osc]
## |   |`- [name:osc1] osc1 page
## |   |`- [name:osc2] osc2 page
## |   |`- [name:osc-sync] osc sync page
## |    `- [name:osc-noise] osc noise page
## |`- [section:filter]
## |   |`- [name:flt1] filter 1 page
## |    `- [name:flt2] filter 2 page
## |`- [section:env]
## |   |`- [name:env1] env1 page
## |    `- [name:env2] env2 page
## |`- [section:lfo]
## |   |`- [name:lfo1] env1 page
## |    `- [name:lfo2] env2 page
##  `- etc...
##
## One possible workflow is to have a set of buttons, which correspond to a section.
## Pressing that button once gets you to the first page of the section.
## Press it again to cycle through the section's pages.

let extRemoteControls*: cstring = cstring"clap.remote-controls/2"

let extRemoteControlsCompat*: cstring = cstring"clap.remote-controls.draft/2"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

const remoteControlsCount* = 8

type
  RemoteControlsPage* {.bycopy.} = object
    sectionName*: array[name_Size, char]
    pageId*: Id
    pageName*: array[name_Size, char]
    paramIds*: array[remoteControlsCount, Id]
    isForPreset*: bool
      ## This is used to separate device pages versus preset pages.
      ## If true, then this page is specific to this preset.

  PluginRemoteControls* {.bycopy.} = object
    count*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Returns the number of pages.
      ## `[main-thread]`
    get*: proc(
      plugin: ptr Plugin, pageIndex: uint32, page: ptr RemoteControlsPage
    ): bool {.cdecl.}
      ## Get a page by index.
      ## Returns true on success and stores the result into `page`.
      ## `[main-thread]`

  HostRemoteControls* {.bycopy.} = object
    changed*: proc(host: ptr Host) {.cdecl.}
      ## Informs the host that the remote controls have changed.
      ## `[main-thread]`
    suggestPage*: proc(host: ptr Host, pageId: Id) {.cdecl.}
      ## Suggest a page to the host because it corresponds to what the user is currently editing in
      ## the plugin's GUI.
      ## `[main-thread]`
