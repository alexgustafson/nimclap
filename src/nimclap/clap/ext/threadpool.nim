import ../plugin, ../host

## Thread pool.
##
## This extension lets the plugin use the host's thread pool.
##
## The plugin must provide `PluginThreadPool`, and the host may provide
## `HostThreadPool`. If it doesn't, the plugin should process its data by its own
## means. In the worst case, a single threaded for-loop.
##
## Simple example with N voices to process
##
## ```
## void myplug_thread_pool_exec(const clap_plugin *plugin, uint32_t voice_index)
## {
##    compute_voice(plugin, voice_index);
## }
##
## void myplug_process(const clap_plugin *plugin, const clap_process *process)
## {
##    ...
##    bool didComputeVoices = false;
##    if (host_thread_pool && host_thread_pool->request_exec)
##       didComputeVoices = host_thread_pool->request_exec(host, N);
##
##    if (!didComputeVoices)
##       for (uint32_t i = 0; i < N; ++i)
##          myplug_thread_pool_exec(plugin, i);
##    ...
## }
## ```
##
## Be aware that using a thread pool may break hard real-time rules due to the
## thread synchronization involved.
##
## If the host knows that it is running under hard real-time pressure it may
## decide to not provide this interface.

let extThreadPool*: cstring = cstring"clap.thread-pool"

type
  PluginThreadPool* {.bycopy.} = object
    exec*: proc(plugin: ptr Plugin, taskIndex: uint32) {.cdecl.}
      ## Called by the thread pool.

  HostThreadPool* {.bycopy.} = object
    requestExec*: proc(host: ptr Host, numTasks: uint32): bool {.cdecl.}
      ## Schedule `numTasks` jobs in the host thread pool.
      ## It can't be called concurrently or from the thread pool.
      ## Will block until all the tasks are processed.
      ## This must be used exclusively for realtime processing within the process
      ## call.
      ## Returns true if the host did execute all the tasks, false if it rejected
      ## the request.
      ## The host should check that the plugin is within the process call, and if
      ## not, reject the exec request.
      ## `[audio-thread]`
