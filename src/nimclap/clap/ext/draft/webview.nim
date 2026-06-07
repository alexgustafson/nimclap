import ../../plugin, ../../stream
import ../../host

let extWebview*: cstring = cstring"clap.webview/3"

let windowApiWebview*: cstring = cstring"webview"
  ## `clap.gui` API constant. The pointer in `Window` must be nil, but sizing
  ## methods are useful. This uses logical size, don't call `PluginGui.setScale`.

## @page Webview
##
## This extension enables the plugin to provide the start-page for a webview UI,
## and exchange messages back and forth.
##
## Messages are received in the webview using a standard MessageEvent, with the
## data in an ArrayBuffer. They are posted back to the plugin using
## `window.parent.postMessage()`, with the data in an ArrayBuffer or TypedArray.

type PluginWebview* {.bycopy.} = object
  getUri*: proc(plugin: ptr Plugin, uri: cstring, uriCapacity: uint32): int32 {.cdecl.}
    ## Writes the URL for the webview's initial navigation to the provided `uri`
    ## buffer as a null-terminated UTF-8 string.
    ##
    ## This must be called at least once before any messages are sent (or
    ## accepted) by the host. Absolute URIs (including `data:`, and `file:` URIs
    ## on local systems) are always supported. Relative URIs (with absolute
    ## paths) refer to resources provided by `getResource`, which may be provided
    ## to the webview with an arbitrary scheme or URI prefix. The host may also
    ## translate `file:` URIs to some other scheme or path root, to limit access
    ## scope or handle virtual filesystems. Therefore, when using either relative
    ## or `file:` URIs, pages must not assume a particular absolute path, only
    ## relative paths between resources.
    ##
    ## Returns either the full length of the URI (including the null terminator),
    ## or <= 0 for an error. If the value returned is greater than the capacity,
    ## then the result was truncated. If the capacity is 0, `uri` may be a nil
    ## pointer. In this case, the length of the URI is returned without writing to
    ## `uri`, allowing the host to preallocate a buffer for a subsequent call.
    ## `[main-thread]`
  getResource*: proc(
    plugin: ptr Plugin,
    path: cstring,
    mime: cstring,
    mimeCapacity: uint32,
    dataStream: ptr Ostream,
  ): bool {.cdecl.}
    ## Provides the media type and data for resources, starting with the URI from
    ## `getUri`. The path must be absolute (starting with `/`) with any
    ## host-defined path prefix removed. Writes the null-terminated media type
    ## (MIME type) to the `mime` output buffer if the capacity is large enough,
    ## and streams resource data to `dataStream`.
    ## Returns true if the media type and entire contents of the resource were
    ## provided.
    ##
    ## See https://www.rfc-editor.org/rfc/rfc6838#section-4.2
    ##
    ## `[main-thread]`
  receive*: proc(plugin: ptr Plugin, buffer: pointer, size: uint32): bool {.cdecl.}
    ## Receives a single message from the webview, which must be open and ready to
    ## receive replies.
    ## Returns true on success.
    ## `[main-thread]`

type HostWebview* {.bycopy.} = object
  send*: proc(host: ptr Host, buffer: pointer, size: uint32): bool {.cdecl.}
    ## Sends a single message to the webview.
    ## Returns true on success. It must fail (false) if the webview is not open.
    ## `[main-thread]`
