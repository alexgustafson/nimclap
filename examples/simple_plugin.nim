import ../src/nimclap


var sMyPlugDesc*: ClapPluginDescriptorT = [
    clapVersion: clap_Version_Init,
    id: "com.your-company.YourPlugin",
    name: "Plugin Name",
    vendor: "Vendor",
    url: "https://your-domain.com/your-plugin",
    manualUrl: "https://your-domain.com/your-plugin/manual",
    supportUrl: "https://your-domain.com/support",
    version: "1.4.2",
    description: "The plugin description.",
    features: cast[UncheckedArray[cstring]]((clap_Plugin_Feature_Instrument, clap_Plugin_Feature_Stereo, nil))]





echo "Build Success"