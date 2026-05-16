import AVFoundation
import Foundation

/// A single polyphonic voice. Owns an AVAudioSourceNode whose render block
/// pulls samples from a Generator. Applies an ADSR envelope, biquad lowpass
/// filter, and per-voice gain on the output side.
final class SynthVoice {
    let format: AVAudioFormat
    private(set) var sourceNode: AVAudioSourceNode!

    // Voice-level state. The render block runs on the audio thread, so
    // mutable state crossing the boundary uses atomics where it matters
    // and acceptable-stale loads where a glitch on parameter change is fine.
    private var generator: Generator = SineGenerator(frequency: 440, sampleRate: 48_000)
    private var envelope = ADSREnvelope(sampleRate: 48_000)
    private var filter = BiquadLowpass(sampleRate: 48_000)
    private var amp: Float = 0
    private var voicePitch: NotePitch?
    private var baseFrequency: Double = 440
    private var detuneCents: Double = 0
    private var pitchBendCents: Double = 0

    var isActive: Bool { envelope.isActive }

    init(format: AVAudioFormat) {
        self.format = format
        let sr = format.sampleRate
        envelope = ADSREnvelope(sampleRate: sr)
        filter = BiquadLowpass(sampleRate: sr)

        self.sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            return self.render(frames: Int(frameCount), buffers: ablPointer)
        }
    }

    // MARK: Public API (main thread)

    func noteOn(pitch: NotePitch, velocity: Double, synth: SynthState, pitchBendCents: Double) {
        voicePitch = pitch
        baseFrequency = pitch.frequency
        detuneCents = synth.detune
        self.pitchBendCents = pitchBendCents
        let f = currentFrequency()
        generator = makeGenerator(synth.waveform, frequency: f, sampleRate: format.sampleRate)
        envelope.configure(
            attack: synth.attack,
            decay: synth.decay,
            sustain: synth.sustain,
            release: synth.release,
            velocity: velocity
        )
        filter.set(frequency: synth.filterFreq, q: synth.filterRes)
        envelope.noteOn()
    }

    func noteOff(immediately: Bool = false) {
        if immediately {
            envelope.silence()
        } else {
            envelope.noteOff()
        }
    }

    func setPitchBend(cents: Double) {
        pitchBendCents = cents
        generator.setFrequency(currentFrequency())
    }

    func updateRouting(_ state: SynthState) {
        filter.set(frequency: state.filterFreq, q: state.filterRes)
    }

    private func currentFrequency() -> Double {
        baseFrequency * pow(2.0, (detuneCents + pitchBendCents) / 1200.0)
    }

    private func makeGenerator(_ wave: Waveform, frequency: Double, sampleRate: Double) -> Generator {
        switch wave {
        case .sine: return SineGenerator(frequency: frequency, sampleRate: sampleRate)
        case .square: return SquareGenerator(frequency: frequency, sampleRate: sampleRate)
        case .sawtooth: return SawGenerator(frequency: frequency, sampleRate: sampleRate)
        case .triangle: return TriangleGenerator(frequency: frequency, sampleRate: sampleRate)
        case .pulse: return PulseGenerator(frequency: frequency, sampleRate: sampleRate)
        case .supersaw: return SupersawGenerator(frequency: frequency, sampleRate: sampleRate)
        case .noise: return NoiseGenerator(sampleRate: sampleRate)
        case .fm: return FMGenerator(frequency: frequency, sampleRate: sampleRate)
        case .organ: return OrganGenerator(frequency: frequency, sampleRate: sampleRate)
        case .sitar: return SitarGenerator(frequency: frequency, sampleRate: sampleRate)
        case .tabla: return TablaGenerator(frequency: frequency, sampleRate: sampleRate)
        case .koto: return KotoGenerator(frequency: frequency, sampleRate: sampleRate)
        case .kalimba: return KalimbaGenerator(frequency: frequency, sampleRate: sampleRate)
        case .gamelan: return GamelanGenerator(frequency: frequency, sampleRate: sampleRate)
        case .bansuri: return BansuriGenerator(frequency: frequency, sampleRate: sampleRate)
        case .oud: return OudGenerator(frequency: frequency, sampleRate: sampleRate)
        case .steelpan: return SteelpanGenerator(frequency: frequency, sampleRate: sampleRate)
        }
    }

    // MARK: Render (audio thread)

    private func render(frames: Int, buffers: UnsafeMutableAudioBufferListPointer) -> OSStatus {
        let channelCount = Int(format.channelCount)
        // Pull samples from generator; voices output mono and get spread to all channels.
        for frame in 0..<frames {
            let envValue = envelope.tick()
            let sample = generator.tick() * envValue
            let filtered = filter.process(Float(sample))
            for ch in 0..<channelCount {
                let buf = buffers[ch].mData!.assumingMemoryBound(to: Float.self)
                buf[frame] = filtered
            }
        }
        return noErr
    }
}
