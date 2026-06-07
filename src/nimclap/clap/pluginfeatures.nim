## This file provides a set of standard plugin features meant to be used
## within `PluginDescriptor.features`.
##
## For practical reasons we'll avoid spaces and use `-` instead to facilitate
## scripts that generate the feature array.
##
## Non-standard features should be formatted as follow: "$namespace:$feature"

## Plugin category

const pluginFeatureInstrument* = "instrument"
  ## Add this feature if your plugin can process note events and then produce
  ## audio.

const pluginFeatureAudioEffect* = "audio-effect"
  ## Add this feature if your plugin is an audio effect.

const pluginFeatureNoteEffect* = "note-effect"
  ## Add this feature if your plugin is a note effect or a note
  ## generator/sequencer.

const pluginFeatureNoteDetector* = "note-detector"
  ## Add this feature if your plugin converts audio to notes.

const pluginFeatureAnalyzer* = "analyzer"
  ## Add this feature if your plugin is an analyzer.

## Plugin sub-category

const
  pluginFeatureSynthesizer* = "synthesizer"
  pluginFeatureSampler* = "sampler"
  pluginFeatureDrum* = "drum"
    ## For single drum.
  pluginFeatureDrumMachine* = "drum-machine"
  pluginFeatureFilter* = "filter"
  pluginFeaturePhaser* = "phaser"
  pluginFeatureEqualizer* = "equalizer"
  pluginFeatureDeesser* = "de-esser"
  pluginFeaturePhaseVocoder* = "phase-vocoder"
  pluginFeatureGranular* = "granular"
  pluginFeatureFrequencyShifter* = "frequency-shifter"
  pluginFeaturePitchShifter* = "pitch-shifter"
  pluginFeatureDistortion* = "distortion"
  pluginFeatureTransientShaper* = "transient-shaper"
  pluginFeatureCompressor* = "compressor"
  pluginFeatureExpander* = "expander"
  pluginFeatureGate* = "gate"
  pluginFeatureLimiter* = "limiter"
  pluginFeatureFlanger* = "flanger"
  pluginFeatureChorus* = "chorus"
  pluginFeatureDelay* = "delay"
  pluginFeatureReverb* = "reverb"
  pluginFeatureTremolo* = "tremolo"
  pluginFeatureGlitch* = "glitch"
  pluginFeatureUtility* = "utility"
  pluginFeaturePitchCorrection* = "pitch-correction"
  pluginFeatureRestoration* = "restoration"
    ## Repair the sound.
  pluginFeatureMultiEffects* = "multi-effects"
  pluginFeatureMixing* = "mixing"
  pluginFeatureMastering* = "mastering"

## Audio Capabilities

const
  pluginFeatureMono* = "mono"
  pluginFeatureStereo* = "stereo"
  pluginFeatureSurround* = "surround"
  pluginFeatureAmbisonic* = "ambisonic"
