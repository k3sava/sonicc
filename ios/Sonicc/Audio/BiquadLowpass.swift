import Foundation

/// Direct-form II transposed biquad lowpass, RBJ coefficients.
///
/// Per-voice lowpass with adjustable cutoff/Q, recomputed only on
/// parameter changes (not per-sample).
struct BiquadLowpass {
    private let sampleRate: Double
    private var b0: Float = 1, b1: Float = 0, b2: Float = 0
    private var a1: Float = 0, a2: Float = 0
    private var z1: Float = 0, z2: Float = 0
    private var lastFreq: Double = 0
    private var lastQ: Double = 0

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        set(frequency: 20_000, q: 0.707)
    }

    mutating func set(frequency: Double, q: Double) {
        let f = max(20, min(sampleRate * 0.45, frequency))
        let qq = max(0.1, min(30, q))
        if f == lastFreq && qq == lastQ { return }
        lastFreq = f; lastQ = qq

        let w0 = 2.0 * Double.pi * f / sampleRate
        let cw = cos(w0)
        let sw = sin(w0)
        let alpha = sw / (2.0 * qq)
        let a0 = 1.0 + alpha
        let _b0 = (1.0 - cw) * 0.5 / a0
        let _b1 = (1.0 - cw) / a0
        let _b2 = (1.0 - cw) * 0.5 / a0
        let _a1 = (-2.0 * cw) / a0
        let _a2 = (1.0 - alpha) / a0
        b0 = Float(_b0); b1 = Float(_b1); b2 = Float(_b2)
        a1 = Float(_a1); a2 = Float(_a2)
    }

    mutating func process(_ x: Float) -> Float {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
}
