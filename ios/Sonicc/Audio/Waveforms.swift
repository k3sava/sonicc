import Foundation

/// Anything that produces one mono sample per tick().
/// Generators are constructed on the main thread when a note starts and
/// then tick on the audio thread. setFrequency() may be called from the
/// audio thread for pitch bend (no allocations).
protocol Generator: AnyObject {
    func tick() -> Double
    func setFrequency(_ f: Double)
}

// MARK: - Basic oscillators

final class SineGenerator: Generator {
    private let sampleRate: Double
    private var phase: Double = 0
    private var inc: Double

    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.inc = 2.0 * .pi * frequency / sampleRate
    }
    func setFrequency(_ f: Double) { inc = 2.0 * .pi * f / sampleRate }
    func tick() -> Double {
        let s = sin(phase)
        phase += inc
        if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        return s
    }
}

final class SquareGenerator: Generator {
    private let sampleRate: Double
    private var phase: Double = 0
    private var inc: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.inc = frequency / sampleRate
    }
    func setFrequency(_ f: Double) { inc = f / sampleRate }
    func tick() -> Double {
        let s = phase < 0.5 ? 1.0 : -1.0
        phase += inc
        if phase >= 1.0 { phase -= 1.0 }
        return s
    }
}

final class SawGenerator: Generator {
    private let sampleRate: Double
    private var phase: Double = 0
    private var inc: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.inc = frequency / sampleRate
    }
    func setFrequency(_ f: Double) { inc = f / sampleRate }
    func tick() -> Double {
        let s = 2.0 * phase - 1.0
        phase += inc
        if phase >= 1.0 { phase -= 1.0 }
        return s
    }
}

final class TriangleGenerator: Generator {
    private let sampleRate: Double
    private var phase: Double = 0
    private var inc: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.inc = frequency / sampleRate
    }
    func setFrequency(_ f: Double) { inc = f / sampleRate }
    func tick() -> Double {
        let s = 4.0 * abs(phase - 0.5) - 1.0
        phase += inc
        if phase >= 1.0 { phase -= 1.0 }
        return s
    }
}

/// Two slightly detuned squares (±7 cents) for a thick pulse.
final class PulseGenerator: Generator {
    private let a: SquareGenerator
    private let b: SquareGenerator
    private let f: Double
    init(frequency: Double, sampleRate: Double) {
        self.f = frequency
        a = SquareGenerator(frequency: frequency * pow(2.0, -7.0 / 1200.0), sampleRate: sampleRate)
        b = SquareGenerator(frequency: frequency * pow(2.0,  7.0 / 1200.0), sampleRate: sampleRate)
    }
    func setFrequency(_ f: Double) {
        a.setFrequency(f * pow(2.0, -7.0 / 1200.0))
        b.setFrequency(f * pow(2.0,  7.0 / 1200.0))
    }
    func tick() -> Double { 0.5 * (a.tick() + b.tick()) }
}

/// Five detuned saws across two octaves: classic supersaw stack.
final class SupersawGenerator: Generator {
    private let voices: [SawGenerator]
    private let detunes: [Double] = [0, -12, 12, -24, 24] // cents
    init(frequency: Double, sampleRate: Double) {
        voices = detunes.map {
            SawGenerator(frequency: frequency * pow(2.0, $0 / 1200.0), sampleRate: sampleRate)
        }
    }
    func setFrequency(_ f: Double) {
        for (i, v) in voices.enumerated() {
            v.setFrequency(f * pow(2.0, detunes[i] / 1200.0))
        }
    }
    func tick() -> Double {
        var s = 0.0
        for v in voices { s += v.tick() }
        return s * 0.22
    }
}

/// White noise (xorshift32 → [-1, 1]).
final class NoiseGenerator: Generator {
    private var state: UInt32 = 0x9E37_79B9
    init(sampleRate: Double) {
        _ = sampleRate
    }
    func setFrequency(_ f: Double) { _ = f }
    func tick() -> Double {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return (Double(state) / Double(UInt32.max)) * 2.0 - 1.0
    }
}

/// Simple two-operator FM: modulator at 2× carrier, index 1.5.
final class FMGenerator: Generator {
    private let sampleRate: Double
    private var carrierPhase: Double = 0
    private var modPhase: Double = 0
    private var freq: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let modInc = 2.0 * .pi * freq * 2.0 / sampleRate
        let mod = sin(modPhase) * 1.5
        modPhase += modInc
        if modPhase > 2.0 * .pi { modPhase -= 2.0 * .pi }
        let carrierInc = 2.0 * .pi * freq / sampleRate
        let s = sin(carrierPhase + mod)
        carrierPhase += carrierInc
        if carrierPhase > 2.0 * .pi { carrierPhase -= 2.0 * .pi }
        return s
    }
}

/// Drawbar-style organ: 1, 2, 3, 4 harmonics at falling amplitudes.
final class OrganGenerator: Generator {
    private let sampleRate: Double
    private var phase: Double = 0
    private var freq: Double
    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.freq = frequency
    }
    func setFrequency(_ f: Double) { freq = f }
    func tick() -> Double {
        let inc = 2.0 * .pi * freq / sampleRate
        let s = sin(phase) * 0.55
              + sin(phase * 2) * 0.30
              + sin(phase * 3) * 0.15
              + sin(phase * 4) * 0.10
        phase += inc
        if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        return s * 0.6
    }
}
