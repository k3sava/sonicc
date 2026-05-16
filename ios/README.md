# Sonicc iOS

Native iOS and iPadOS port of Sonicc — a music playground with keys, drums, sequencer, sampler, microphone, and MIDI.

This is not a wrapped web view. Audio runs on AVAudioEngine, MIDI runs on Core MIDI, and the UI is SwiftUI with adaptive layouts for iPhone and iPad.

## What's here

- `Sonicc.xcodeproj` — open in Xcode 15.4+
- `Sonicc/` — Swift sources
- `project.yml` — XcodeGen spec; if `project.pbxproj` ever drifts from the file tree, run `xcodegen generate` to rebuild it

## Requirements

- Xcode 15.4 or later
- iOS / iPadOS 17.0+
- Mac with Apple Silicon or Intel running macOS Sonoma+ for development
- A physical device is recommended for audio latency and MIDI; the simulator works for UI

## Build & run

1. `open Sonicc.xcodeproj`
2. Select the **Sonicc** scheme and a device
3. ⌘R

For microphone and MIDI, the app requests permissions on first use. Both are declared in `Info.plist`.

## Architecture

```
SoniccApp                       app entry, scene root
└── ContentView                 size-class router → iPad or iPhone shell
    ├── IPadRootView            NavigationSplitView 3-pane
    └── IPhoneRootView          TabView, sheets for inspector

AppState (ObservableObject)     global UI state, hands references to:
├── AudioEngine                 AVAudioEngine wrapper, signal graph
│   ├── VoiceAllocator          16-voice polyphony, voice stealing
│   ├── SynthVoice              one voice = one AVAudioSourceNode + ADSR
│   ├── Waveforms               sine, square, saw, tri, pulse, supersaw,
│   │                           noise, FM, organ
│   ├── WorldInstruments        sitar, tabla, koto, kalimba, gamelan,
│   │                           bansuri, oud, steelpan
│   ├── DrumSynth               kick, snare, hat, clap, tom, crash,
│   │                           perc, cowbell
│   └── EffectsRack             reverb, delay, distortion, lo-fi,
│                               chorus, phaser, compressor, bitcrusher,
│                               tremolo, EQ, flanger, autowah
├── Sequencer                   8/16/32/64-step grid, swing, recording
├── SamplerEngine               4 pads, in-buffer slicing, loop
├── MicrophoneRecorder          AVAudioEngine input tap → AAC/WAV
├── MIDIManager                 Core MIDI in, GM drums on ch10
└── ThemeManager                5 themes, persisted to UserDefaults
```

### iPad vs iPhone

The iPad is a real iPad app. Three-column NavigationSplitView (modes + inspector + content). Drum pads on iPad use a 4×2 grid that scales to the available pane width; pattern grid expands to all 64 steps without scrolling on 13" iPad; keyboard supports two-row playable layout in landscape.

iPhone uses a single primary view with a bottom mode tab. The inspector and presets surface in sheets to keep the playable area maximized.

Both share the exact same engine and state; only the View layer differs.

## Module responsibilities

| File | Responsibility |
|------|----------------|
| `Audio/AudioEngine.swift` | Build/teardown `AVAudioEngine`, wire fx chain |
| `Audio/SynthVoice.swift` | Per-voice DSP host, ADSR, detune, pan |
| `Audio/Waveforms.swift` | Sample generators for every basic waveform |
| `Audio/Instruments/*.swift` | Spectral models for sitar, tabla, etc. |
| `Audio/Effects/*.swift` | Custom DSP for chorus, phaser, bitcrusher, etc. |
| `Sequencer/Sequencer.swift` | Step clock, pattern storage, playback |
| `Sampler/SamplerEngine.swift` | 4-pad buffer playback with slice markers |
| `Microphone/MicrophoneRecorder.swift` | Input tap, level meter, file export |
| `MIDI/MIDIManager.swift` | Core MIDI sources, CC mapping, pitch bend |
| `Presets/PresetLibrary.swift` | 16 factory presets |
| `Themes/ThemeLibrary.swift` | 5 themes; light, brutalist, editorial, terminal, zen |

## License

MIT — same as the parent repo.
