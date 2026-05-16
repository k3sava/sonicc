import Foundation

struct Preset: Identifiable, Hashable {
    let id: String
    let displayName: String
    let synth: SynthState
}

/// 16 factory presets ported from index.html.
final class PresetLibrary {
    let presets: [Preset]
    private let byID: [String: Preset]

    init() {
        let list: [Preset] = [
            Preset(id: "pad", displayName: "pad", synth: {
                var s = SynthState()
                s.waveform = .sine
                s.attack = 0.4; s.decay = 0.3; s.sustain = 0.8; s.release = 1.2
                s.filterFreq = 3_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "lead", displayName: "lead", synth: {
                var s = SynthState()
                s.waveform = .sawtooth
                s.attack = 0.005; s.decay = 0.1; s.sustain = 0.6; s.release = 0.2
                s.filterFreq = 6_000
                s.fx.delay = true
                return s
            }()),
            Preset(id: "bass", displayName: "bass", synth: {
                var s = SynthState()
                s.waveform = .sawtooth
                s.attack = 0.01; s.decay = 0.1; s.sustain = 0.7; s.release = 0.2
                s.filterFreq = 800
                return s
            }()),
            Preset(id: "pluck", displayName: "pluck", synth: {
                var s = SynthState()
                s.waveform = .triangle
                s.attack = 0.001; s.decay = 0.2; s.sustain = 0.0; s.release = 0.4
                s.filterFreq = 4_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "bell", displayName: "bell", synth: {
                var s = SynthState()
                s.waveform = .fm
                s.attack = 0.005; s.decay = 0.8; s.sustain = 0.0; s.release = 1.0
                s.filterFreq = 12_000
                s.fx.reverb = true; s.fx.delay = true
                return s
            }()),
            Preset(id: "organ", displayName: "organ", synth: {
                var s = SynthState()
                s.waveform = .organ
                s.attack = 0.01; s.decay = 0.01; s.sustain = 0.9; s.release = 0.1
                s.filterFreq = 5_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "epiano", displayName: "e.piano", synth: {
                var s = SynthState()
                s.waveform = .triangle
                s.attack = 0.005; s.decay = 0.3; s.sustain = 0.2; s.release = 0.4
                s.filterFreq = 7_000
                return s
            }()),
            Preset(id: "sub", displayName: "sub", synth: {
                var s = SynthState()
                s.waveform = .sine
                s.attack = 0.01; s.decay = 0.1; s.sustain = 0.9; s.release = 0.2
                s.filterFreq = 300
                s.fx.distortion = true
                return s
            }()),
            Preset(id: "sitar", displayName: "sitar", synth: {
                var s = SynthState()
                s.waveform = .sitar
                s.attack = 0.005; s.decay = 0.6; s.sustain = 0.3; s.release = 0.6
                s.filterFreq = 6_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "tabla", displayName: "tabla", synth: {
                var s = SynthState()
                s.waveform = .tabla
                s.attack = 0.001; s.decay = 0.4; s.sustain = 0.02; s.release = 0.3
                s.filterFreq = 4_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "koto", displayName: "koto", synth: {
                var s = SynthState()
                s.waveform = .koto
                s.attack = 0.001; s.decay = 0.4; s.sustain = 0.2; s.release = 0.6
                s.filterFreq = 7_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "kalimba", displayName: "kalimba", synth: {
                var s = SynthState()
                s.waveform = .kalimba
                s.attack = 0.001; s.decay = 0.6; s.sustain = 0.1; s.release = 0.4
                s.filterFreq = 12_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "gamelan", displayName: "gamelan", synth: {
                var s = SynthState()
                s.waveform = .gamelan
                s.attack = 0.002; s.decay = 0.8; s.sustain = 0.05; s.release = 1.2
                s.filterFreq = 10_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "bansuri", displayName: "bansuri", synth: {
                var s = SynthState()
                s.waveform = .bansuri
                s.attack = 0.08; s.decay = 0.2; s.sustain = 0.7; s.release = 0.5
                s.filterFreq = 3_000
                s.fx.reverb = true; s.fx.tremolo = true
                return s
            }()),
            Preset(id: "oud", displayName: "oud", synth: {
                var s = SynthState()
                s.waveform = .oud
                s.attack = 0.002; s.decay = 0.3; s.sustain = 0.4; s.release = 0.4
                s.filterFreq = 3_000
                s.fx.reverb = true
                return s
            }()),
            Preset(id: "steelpan", displayName: "steelpan", synth: {
                var s = SynthState()
                s.waveform = .steelpan
                s.attack = 0.001; s.decay = 0.5; s.sustain = 0.2; s.release = 0.6
                s.filterFreq = 9_000
                s.fx.reverb = true; s.fx.delay = true
                return s
            }()),
        ]
        self.presets = list
        self.byID = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    func preset(id: String) -> Preset? { byID[id] }
}
