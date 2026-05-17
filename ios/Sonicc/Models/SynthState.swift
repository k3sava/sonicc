import Foundation

struct SynthState: Equatable, Hashable {
    var waveform: Waveform = .sine
    var attack: Double = 0.01     // seconds
    var decay: Double = 0.1
    var sustain: Double = 0.7     // 0..1
    var release: Double = 0.3
    var filterFreq: Double = 4_000 // Hz
    var filterRes: Double = 1.0
    var volume: Double = 0.7
    var detune: Double = 0         // cents
    var pan: Double = 0            // -1..1

    var fx: FXState = .init()

    struct FXState: Equatable, Hashable {
        var reverb: Bool = false
        var delay: Bool = false
        var distortion: Bool = false
        var lofi: Bool = false
        var chorus: Bool = false
        var phaser: Bool = false
        var compressor: Bool = false
        var bitcrusher: Bool = false
        var tremolo: Bool = false
        var eq: Bool = false
        var flanger: Bool = false
        var autowah: Bool = false
    }
}

enum Waveform: String, CaseIterable, Identifiable, Equatable, Hashable {
    case sine, square, sawtooth, triangle
    case pulse, supersaw, noise, fm, organ
    // World instruments — synthesis presets
    case sitar, tabla, koto, kalimba, gamelan, bansuri, oud, steelpan

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .sine: return "sine"
        case .square: return "square"
        case .sawtooth: return "saw"
        case .triangle: return "triangle"
        case .pulse: return "pulse"
        case .supersaw: return "supersaw"
        case .noise: return "noise"
        case .fm: return "fm"
        case .organ: return "organ"
        case .sitar: return "sitar"
        case .tabla: return "tabla"
        case .koto: return "koto"
        case .kalimba: return "kalimba"
        case .gamelan: return "gamelan"
        case .bansuri: return "bansuri"
        case .oud: return "oud"
        case .steelpan: return "steelpan"
        }
    }

    var isWorld: Bool {
        switch self {
        case .sitar, .tabla, .koto, .kalimba, .gamelan, .bansuri, .oud, .steelpan: return true
        default: return false
        }
    }
}
