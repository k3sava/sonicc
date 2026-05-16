import AVFoundation
import Foundation

/// Manages a fixed pool of polyphonic voices, with oldest-first stealing
/// when the pool overflows. Mirrors the activeNotes map in index.html.
final class VoiceAllocator {
    let voices: [SynthVoice]
    private var activePitchToVoice: [NotePitch: SynthVoice] = [:]
    private var voiceOrder: [SynthVoice] = []
    private var pitchBendCents: Double = 0

    init(format: AVAudioFormat, maxVoices: Int) {
        self.voices = (0..<maxVoices).map { _ in SynthVoice(format: format) }
    }

    func applyDefaults(_ state: SynthState) {
        for v in voices { v.updateRouting(state) }
    }

    func noteOn(pitch: NotePitch, velocity: Double, synth: SynthState, pitchBendCents: Double) {
        if let existing = activePitchToVoice[pitch] {
            existing.noteOff(immediately: true)
            voiceOrder.removeAll { $0 === existing }
            activePitchToVoice[pitch] = nil
        }
        let voice = pickVoice()
        voice.noteOn(
            pitch: pitch,
            velocity: velocity,
            synth: synth,
            pitchBendCents: pitchBendCents
        )
        activePitchToVoice[pitch] = voice
        voiceOrder.append(voice)
    }

    func noteOff(pitch: NotePitch) {
        guard let voice = activePitchToVoice[pitch] else { return }
        voice.noteOff()
        activePitchToVoice[pitch] = nil
    }

    func setPitchBend(cents: Double) {
        pitchBendCents = cents
        for v in voices { v.setPitchBend(cents: cents) }
    }

    private func pickVoice() -> SynthVoice {
        if let free = voices.first(where: { !$0.isActive }) { return free }
        // Steal the oldest active voice.
        let stolen = voiceOrder.removeFirst()
        stolen.noteOff(immediately: true)
        activePitchToVoice = activePitchToVoice.filter { $0.value !== stolen }
        return stolen
    }
}
