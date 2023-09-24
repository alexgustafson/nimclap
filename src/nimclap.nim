# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import nimclap/clap/version
import nimclap/clap/plugin

export version
export plugin




type
    ClapPluginDescriptor* = clap_plugin_descriptor