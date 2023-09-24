##  This file provides a set of standard plugin features meant to be used
##  within clap_plugin_descriptor.features.
##
##  For practical reasons we'll avoid spaces and use `-` instead to facilitate
##  scripts that generate the feature array.
##
##  Non-standard features should be formatted as follow: "$namespace:$feature"
## //////////////////
##  Plugin category //
## //////////////////
##  Add this feature if your plugin can process note events and then produce audio

const
  CLAP_PLUGIN_FEATURE_INSTRUMENT* = "instrument"

##  Add this feature if your plugin is an audio effect

const
  CLAP_PLUGIN_FEATURE_AUDIO_EFFECT* = "audio-effect"

##  Add this feature if your plugin is a note effect or a note generator/sequencer

const
  CLAP_PLUGIN_FEATURE_NOTE_EFFECT* = "note-effect"

##  Add this feature if your plugin converts audio to notes

const
  CLAP_PLUGIN_FEATURE_NOTE_DETECTOR* = "note-detector"

##  Add this feature if your plugin is an analyzer

const
  CLAP_PLUGIN_FEATURE_ANALYZER* = "analyzer"

## //////////////////////
##  Plugin sub-category //
## //////////////////////

const
  CLAP_PLUGIN_FEATURE_SYNTHESIZER* = "synthesizer"
  CLAP_PLUGIN_FEATURE_SAMPLER* = "sampler"
  CLAP_PLUGIN_FEATURE_DRUM* = "drum"
  CLAP_PLUGIN_FEATURE_DRUM_MACHINE* = "drum-machine"
  CLAP_PLUGIN_FEATURE_FILTER* = "filter"
  CLAP_PLUGIN_FEATURE_PHASER* = "phaser"
  CLAP_PLUGIN_FEATURE_EQUALIZER* = "equalizer"
  CLAP_PLUGIN_FEATURE_DEESSER* = "de-esser"
  CLAP_PLUGIN_FEATURE_PHASE_VOCODER* = "phase-vocoder"
  CLAP_PLUGIN_FEATURE_GRANULAR* = "granular"
  CLAP_PLUGIN_FEATURE_FREQUENCY_SHIFTER* = "frequency-shifter"
  CLAP_PLUGIN_FEATURE_PITCH_SHIFTER* = "pitch-shifter"
  CLAP_PLUGIN_FEATURE_DISTORTION* = "distortion"
  CLAP_PLUGIN_FEATURE_TRANSIENT_SHAPER* = "transient-shaper"
  CLAP_PLUGIN_FEATURE_COMPRESSOR* = "compressor"
  CLAP_PLUGIN_FEATURE_EXPANDER* = "expander"
  CLAP_PLUGIN_FEATURE_GATE* = "gate"
  CLAP_PLUGIN_FEATURE_LIMITER* = "limiter"
  CLAP_PLUGIN_FEATURE_FLANGER* = "flanger"
  CLAP_PLUGIN_FEATURE_CHORUS* = "chorus"
  CLAP_PLUGIN_FEATURE_DELAY* = "delay"
  CLAP_PLUGIN_FEATURE_REVERB* = "reverb"
  CLAP_PLUGIN_FEATURE_TREMOLO* = "tremolo"
  CLAP_PLUGIN_FEATURE_GLITCH* = "glitch"
  CLAP_PLUGIN_FEATURE_UTILITY* = "utility"
  CLAP_PLUGIN_FEATURE_PITCH_CORRECTION* = "pitch-correction"
  CLAP_PLUGIN_FEATURE_RESTORATION* = "restoration"
  CLAP_PLUGIN_FEATURE_MULTI_EFFECTS* = "multi-effects"
  CLAP_PLUGIN_FEATURE_MIXING* = "mixing"
  CLAP_PLUGIN_FEATURE_MASTERING* = "mastering"

## /////////////////////
##  Audio Capabilities //
## /////////////////////

const
  CLAP_PLUGIN_FEATURE_MONO* = "mono"
  CLAP_PLUGIN_FEATURE_STEREO* = "stereo"
  CLAP_PLUGIN_FEATURE_SURROUND* = "surround"
  CLAP_PLUGIN_FEATURE_AMBISONIC* = "ambisonic"
