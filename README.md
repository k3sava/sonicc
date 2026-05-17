# sonicc

Browser-native music playground. Keys, drums, sequencer, sampler, mic input, MIDI — all in a single HTML file, no build step.

Runs anywhere that opens an HTML page. Uses the Web Audio API directly: custom waveforms (pulse, supersaw, noise, FM), FX chain (chorus, phaser, compressor, bitcrusher, tremolo, EQ), 16 presets spanning world and electronic sounds.

## Run it

Open `index.html` in any modern browser. That's it.

Or serve locally:

```sh
python3 -m http.server 8000
# then visit http://localhost:8000
```

## Features

- **Instruments** — keyboard (polyphonic), drum pad, synth pad, sampler
- **Sequencer** — step sequencer with swing and per-step velocity
- **FX** — chorus, phaser, compressor, bitcrusher, tremolo, EQ, reverb, delay
- **Input** — microphone capture, MIDI devices (Web MIDI)
- **Presets** — 16 built-in across world music and electronic styles
- **Shortcuts** — full keyboard control for live performance

## Native iOS / iPadOS

A real native port lives in [`ios/`](ios/) — open `ios/Sonicc.xcodeproj` in
Xcode 15.4+ and run. The iPad gets a three-pane split view (modes,
performance surface, FX inspector). The iPhone gets a single-pane layout
with sheets for the inspector and presets. Same engine, same presets,
written directly on AVAudioEngine and Core MIDI.

## License

MIT — fork, extend, ship. See [LICENSE](LICENSE).
