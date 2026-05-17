import Foundation

// World/exotic instrument generators. These approximate the spectral
// recipes from index.html — additive partials, inharmonic ratios, and a
// few per-instrument quirks (jawari buzz, breath noise, FM attack).

/// Sitar: sawtooth carrier + FM modulator + four sympathetic partials.
final class SitarGenerator: Generator {
    private let sampleRate: Double
    private var carrierPhase = 0.0
    private var modPhase = 0.0
    private var sympPhase: [Double] = [0, 0, 0, 0]
    private var freq: Double
    private let sympRatios: [Double] = [2.0, 3.0, 4.5, 6.0]
    private let sympGains: [Double] = [0.12, 0.08, 0.06, 0.04]

    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        // Carrier (saw approx)
        carrierPhase += freq / sampleRate
        if carrierPhase >= 1 { carrierPhase -= 1 }
        let saw = 2.0 * carrierPhase - 1.0
        // FM modulator at 2x freq for buzzy attack
        modPhase += twoPi * freq * 2.0 / sampleRate
        if modPhase > twoPi { modPhase -= twoPi }
        let mod = sin(modPhase) * 0.6
        // Jawari buzz: gentle wave-shape distortion
        let buzz = tanh(saw * 2.5 + mod)
        var s = buzz * 0.5
        // Sympathetic strings
        for i in 0..<4 {
            sympPhase[i] += twoPi * freq * sympRatios[i] / sampleRate
            if sympPhase[i] > twoPi { sympPhase[i] -= twoPi }
            s += sin(sympPhase[i]) * sympGains[i]
        }
        return s * 0.8
    }
}

/// Tabla: 5 inharmonic partials with pitch-bend decay and syahi resonance.
final class TablaGenerator: Generator {
    private let sampleRate: Double
    private var partialPhase: [Double] = Array(repeating: 0, count: 5)
    private let ratios: [Double] = [1.0, 1.59, 2.14, 2.65, 3.16]
    private let gains: [Double] = [0.45, 0.22, 0.15, 0.12, 0.08]
    private var freq: Double
    private var t: Double = 0

    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        // Pitch glide down for that characteristic tabla pitch dip.
        let pitchEnv = 1.0 + 0.15 * exp(-t * 25.0)
        var s = 0.0
        for i in 0..<5 {
            partialPhase[i] += twoPi * freq * ratios[i] * pitchEnv / sampleRate
            if partialPhase[i] > twoPi { partialPhase[i] -= twoPi }
            s += sin(partialPhase[i]) * gains[i]
        }
        t += 1.0 / sampleRate
        return s
    }
}

/// Koto: triangle fundamental + 2nd & 3rd harmonics.
final class KotoGenerator: Generator {
    private let sampleRate: Double
    private var phase = 0.0
    private var freq: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        phase += twoPi * freq / sampleRate
        if phase > twoPi { phase -= twoPi }
        // Triangle from phase
        let t = phase / twoPi
        let tri = 4.0 * abs(t - 0.5) - 1.0
        let h2 = sin(phase * 2) * 0.3
        let h3 = sin(phase * 3) * 0.15
        return (tri * 0.6 + h2 + h3) * 0.7
    }
}

/// Kalimba: 4 inharmonic partials.
final class KalimbaGenerator: Generator {
    private let sampleRate: Double
    private var partialPhase: [Double] = Array(repeating: 0, count: 4)
    private let ratios: [Double] = [1.0, 2.76, 5.4, 8.93]
    private let gains: [Double] = [0.5, 0.25, 0.15, 0.08]
    private var freq: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        var s = 0.0
        for i in 0..<4 {
            partialPhase[i] += twoPi * freq * ratios[i] / sampleRate
            if partialPhase[i] > twoPi { partialPhase[i] -= twoPi }
            s += sin(partialPhase[i]) * gains[i]
        }
        return s
    }
}

/// Gamelan: 5 inharmonic partials with a beating pair near the fundamental.
final class GamelanGenerator: Generator {
    private let sampleRate: Double
    private var partialPhase: [Double] = Array(repeating: 0, count: 6)
    private let ratios: [Double] = [1.0, 1.01, 2.4, 3.8, 5.2, 7.1]
    private let gains: [Double] = [0.35, 0.30, 0.18, 0.12, 0.08, 0.05]
    private var freq: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        var s = 0.0
        for i in 0..<6 {
            partialPhase[i] += twoPi * freq * ratios[i] / sampleRate
            if partialPhase[i] > twoPi { partialPhase[i] -= twoPi }
            s += sin(partialPhase[i]) * gains[i]
        }
        return s
    }
}

/// Bansuri: pure-ish sine with breath noise and slight vibrato.
final class BansuriGenerator: Generator {
    private let sampleRate: Double
    private var phase = 0.0
    private var vibPhase = 0.0
    private var freq: Double
    private var noise = NoiseGenerator(sampleRate: 48_000)
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        vibPhase += twoPi * 5.0 / sampleRate
        if vibPhase > twoPi { vibPhase -= twoPi }
        let vib = sin(vibPhase) * 0.005 // ±0.5% pitch wobble
        let f = freq * (1.0 + vib)
        phase += twoPi * f / sampleRate
        if phase > twoPi { phase -= twoPi }
        let body = sin(phase) * 0.6 + sin(phase * 2) * 0.1 + sin(phase * 3) * 0.05
        let breath = noise.tick() * 0.04
        return body + breath
    }
}

/// Oud: 6 harmonic partials with slight upper-harmonic detuning.
final class OudGenerator: Generator {
    private let sampleRate: Double
    private var phase: [Double] = Array(repeating: 0, count: 6)
    private let gains: [Double] = [0.45, 0.30, 0.18, 0.12, 0.08, 0.05]
    private let detunes: [Double] = [0, 0, 1.005, 0.995, 1.01, 0.99]
    private var freq: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        var s = 0.0
        for i in 0..<6 {
            phase[i] += twoPi * freq * Double(i + 1) * detunes[i] / sampleRate
            if phase[i] > twoPi { phase[i] -= twoPi }
            s += sin(phase[i]) * gains[i]
        }
        return s
    }
}

/// Steelpan: sine fundamental w/ FM attack, octave w/ beating pair, fifth.
final class SteelpanGenerator: Generator {
    private let sampleRate: Double
    private var phaseFund = 0.0
    private var phaseOct1 = 0.0
    private var phaseOct2 = 0.0
    private var phaseFifth = 0.0
    private var modPhase = 0.0
    private var freq: Double
    private var t: Double = 0
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let twoPi = 2.0 * Double.pi
        // FM strike envelope: heavy at t=0, fades fast.
        let strike = exp(-t * 25.0)
        modPhase += twoPi * freq * 3.0 / sampleRate
        if modPhase > twoPi { modPhase -= twoPi }
        let mod = sin(modPhase) * strike * 0.8
        phaseFund += twoPi * freq / sampleRate
        phaseOct1 += twoPi * freq * 2.0 / sampleRate
        phaseOct2 += twoPi * freq * 2.01 / sampleRate
        phaseFifth += twoPi * freq * 3.0 / sampleRate
        if phaseFund > twoPi { phaseFund -= twoPi }
        if phaseOct1 > twoPi { phaseOct1 -= twoPi }
        if phaseOct2 > twoPi { phaseOct2 -= twoPi }
        if phaseFifth > twoPi { phaseFifth -= twoPi }
        let s = sin(phaseFund + mod) * 0.45
              + sin(phaseOct1) * 0.20
              + sin(phaseOct2) * 0.20
              + sin(phaseFifth) * 0.12
        t += 1.0 / sampleRate
        return s
    }
}
