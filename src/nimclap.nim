# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import nimclap/clap/version
import nimclap/clap/plugin
import nimclap/clap/pluginfeatures
import nimclap/clap/host
import nimclap/clap/id
import nimclap/clap/stringsizes

import nimclap/clap/ext/latency
import nimclap/clap/ext/log
import nimclap/clap/ext/state
import nimclap/clap/ext/threadcheck
import nimclap/clap/ext/audioports


export version
export plugin
export pluginfeatures
export host
export id
export stringsizes

export latency
export log
export state
export threadcheck
export audioports


type
    ClapPluginDescriptor* = clap_plugin_descriptor
    ClapPlugin* = clap_plugin
    ClapHost* = clap_host
    ClapHostLatency* = clap_host_latency
    ClapPluginAudioPorts* = clap_plugin_audio_ports