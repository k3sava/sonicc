import AVFoundation
import Foundation

/// 8-voice drum synthesizer. Each hit produces a one-shot envelope/pitch
/// recipe written into its own sample buffer, then mixed in the render block.
/// Implementations of each drum mirror the Web Audio shapes from index.html.
final class DrumSynth {
    private(set) var sourceNode: AVAudioSourceNode!
    private let format: AVAudioFormat
    private let sampleRate: Double
    private let lock = NSLock() // guards voicePool
    private var voicePool: [DrumVoice] = []

    init(format: AVAudioFormat) {
        self.format = format
        self.sampleRate = format.sampleRate
        self.sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            return self.render(frames: Int(frameCount), buffers: ablPointer)
        }
    }

    func trigger(index: Int) {
        let kind = DrumKind(rawValue: index) ?? .kick
        let voice = DrumVoice(kind: kind, sampleRate: sampleRate)
        lock.lock(); voicePool.append(voice); lock.unlock()
    }

    private func render(frames: Int, buffers: UnsafeMutableAudioBufferListPointer) -> OSStatus {
        let channelCount = Int(format.channelCount)
        // Zero buffers first.
        for ch in 0..<channelCount {
            let buf = buffers[ch].mData!.assumingMemoryBound(to: Float.self)
            for i in 0..<frames { buf[i] = 0 }
        }
        lock.lock()
        let active = voicePool
        lock.unlock()
        for voice in active where voice.isActive {
            for frame in 0..<frames {
                let s = voice.tick()
                for ch in 0..<channelCount {
                    let buf = buffers[ch].mData!.assumingMemoryBound(to: Float.self)
                    buf[frame] += s
                }
            }
        }
        // Reap finished voices.
        lock.lock()
        voicePool.removeAll { !$0.isActive }
        lock.unlock()
        return noErr
    }
}

enum DrumKind: Int, CaseIterable {
    case kick = 0, snare, hihat, clap, tom, crash, perc, cowbell
    var label: String {
        switch self {
        case .kick: return "kick"
        case .snare: return "snare"
        case .hihat: return "hi-hat"
        case .clap: return "clap"
        case .tom: return "tom"
        case .crash: return "crash"
        case .perc: return "perc"
        case .cowbell: return "cowbell"
        }
    }
}

/// One-shot drum voice. Each tick advances internal phase + envelope.
final class DrumVoice {
    private let kind: DrumKind
    private let sampleRate: Double
    private var t: Double = 0
    private(set) var isActive: Bool = true

    // Per-drum DSP state
    private var phase: Double = 0
    private var phase2: Double = 0
    private var noise = NoiseGenerator(sampleRate: 48_000)
    private var bp1 = BiquadBand(); private var bp2 = BiquadBand()
    private var hp = BiquadHP()

    init(kind: DrumKind, sampleRate: Double) {
        self.kind = kind
        self.sampleRate = sampleRate
        switch kind {
        case .snare:
            bp1.set(frequency: 2000, q: 1, sampleRate: sampleRate)
        case .clap:
            bp1.set(frequency: 1400, q: 1.2, sampleRate: sampleRate)
        case .hihat, .crash:
            hp.set(frequency: kind == .hihat ? 9000 : 5000, q: 0.7, sampleRate: sampleRate)
        case .cowbell:
            bp1.set(frequency: 845, q: 6, sampleRate: sampleRate)
        default: break
        }
    }

    func tick() -> Float {
        let dt = 1.0 / sampleRate
        let s: Float
        switch kind {
        case .kick:
            let env = exp(-t * 12.0) // fast amp decay
            let pitchEnv = exp(-t * 35.0)
            let f = 38.0 + (190.0 - 38.0) * pitchEnv
            phase += 2.0 * .pi * f * dt
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
            s = Float(sin(phase) * env)
            if t > 0.5 { isActive = false }
        case .snare:
            let env = exp(-t * 18.0)
            let n = noise.tick()
            let filtered = bp1.process(Float(n))
            s = filtered * Float(env) * 1.4
            if t > 0.35 { isActive = false }
        case .hihat:
            let env = exp(-t * 35.0)
            let n = Float(noise.tick())
            s = hp.process(n) * Float(env) * 1.2
            if t > 0.2 { isActive = false }
        case .clap:
            // 3 staggered bursts.
            let bursts = [0.0, 0.012, 0.024]
            var n = 0.0
            for (i, delay) in bursts.enumerated() {
                if t > delay {
                    let dt2 = t - delay
                    n += Double(noise.tick()) * exp(-dt2 * 80.0) * (i == 2 ? 1.4 : 0.9)
                }
            }
            let filt = bp1.process(Float(n))
            s = filt * 1.1
            if t > 0.3 { isActive = false }
        case .tom:
            let env = exp(-t * 8.0)
            let pitchEnv = exp(-t * 18.0)
            let f = 50.0 + (140.0 - 50.0) * pitchEnv
            phase += 2.0 * .pi * f * dt
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
            s = Float(sin(phase) * env)
            if t > 0.7 { isActive = false }
        case .crash:
            let env = exp(-t * 2.5)
            let n = Float(noise.tick())
            s = hp.process(n) * Float(env) * 0.8
            if t > 1.5 { isActive = false }
        case .perc:
            let env = exp(-t * 22.0)
            let pitchEnv = exp(-t * 28.0)
            let f = 160.0 + (520.0 - 160.0) * pitchEnv
            phase += f * dt
            if phase >= 1 { phase -= 1 }
            let tri = 4.0 * abs(phase - 0.5) - 1.0
            s = Float(tri * env)
            if t > 0.25 { isActive = false }
        case .cowbell:
            let env = exp(-t * 9.0)
            phase += 2.0 * .pi * 540 * dt
            phase2 += 2.0 * .pi * 800 * dt
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
            if phase2 > 2.0 * .pi { phase2 -= 2.0 * .pi }
            let sq1 = phase < .pi ? 1.0 : -1.0
            let sq2 = phase2 < .pi ? 1.0 : -1.0
            let mix = (sq1 * 0.5 + sq2 * 0.5)
            s = bp1.process(Float(mix * env)) * 0.9
            if t > 0.45 { isActive = false }
        }
        t += dt
        return s
    }
}

/// Minimal bandpass biquad used by the drum synth (RBJ).
struct BiquadBand {
    private var b0: Float = 1, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0
    private var z1: Float = 0, z2: Float = 0
    mutating func set(frequency: Double, q: Double, sampleRate: Double) {
        let w0 = 2.0 * .pi * frequency / sampleRate
        let cw = cos(w0); let sw = sin(w0)
        let alpha = sw / (2.0 * q)
        let a0 = 1.0 + alpha
        b0 = Float(alpha / a0)
        b1 = 0
        b2 = Float(-alpha / a0)
        a1 = Float(-2.0 * cw / a0)
        a2 = Float((1.0 - alpha) / a0)
    }
    mutating func process(_ x: Float) -> Float {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
}

/// Minimal highpass biquad used by the drum synth (RBJ).
struct BiquadHP {
    private var b0: Float = 1, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0
    private var z1: Float = 0, z2: Float = 0
    mutating func set(frequency: Double, q: Double, sampleRate: Double) {
        let w0 = 2.0 * .pi * frequency / sampleRate
        let cw = cos(w0); let sw = sin(w0)
        let alpha = sw / (2.0 * q)
        let a0 = 1.0 + alpha
        b0 = Float((1.0 + cw) * 0.5 / a0)
        b1 = Float(-(1.0 + cw) / a0)
        b2 = Float((1.0 + cw) * 0.5 / a0)
        a1 = Float(-2.0 * cw / a0)
        a2 = Float((1.0 - alpha) / a0)
    }
    mutating func process(_ x: Float) -> Float {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
}
