import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let audio = AudioEngine()
    let sequencer = Sequencer()
    let sampler = SamplerEngine()
    let mic = MicrophoneRecorder()
    let midi = MIDIManager()
    let presets = PresetLibrary()

    @Published var mode: Mode = .keys
    @Published var synth = SynthState()
    @Published var baseOctave: Int = 4
    @Published var currentPresetID: String = "pad"
    @Published var heldNotes: Set<NotePitch> = []
    @Published var pitchBend: Double = 0 // -1...1
    @Published var midiConnected: Bool = false
    @Published var theme: AppTheme
    @Published var scaleSelection: ScaleSelection = .none
    @Published var sustainHeld: Bool = false
    @Published var velocitySensitive: Bool = true
    // Notes that are released by user touch but still held by sustain.
    @Published var sustainedNotes: Set<NotePitch> = []

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        UserDefaults.standard.set(theme.id, forKey: AppTheme.storageKey)
    }

    enum Mode: String, CaseIterable, Identifiable {
        case keys, drums, pattern, sampler, mic
        var id: String { rawValue }
        var title: String {
            switch self {
            case .keys: return "Keys"
            case .drums: return "Drums"
            case .pattern: return "Pattern"
            case .sampler: return "Sampler"
            case .mic: return "Mic"
            }
        }
        var sfSymbol: String {
            switch self {
            case .keys: return "pianokeys"
            case .drums: return "circle.grid.3x3.fill"
            case .pattern: return "square.grid.4x3.fill"
            case .sampler: return "waveform"
            case .mic: return "mic.fill"
            }
        }
    }

    private var bag: Set<AnyCancellable> = []

    init() {
        let savedID = UserDefaults.standard.string(forKey: AppTheme.storageKey)
        self.theme = AppTheme.all.first(where: { $0.id == savedID }) ?? .default
        sequencer.bind(audio: audio, state: self)
        midi.bind(audio: audio, sequencer: sequencer, state: self)
        applyPreset(id: currentPresetID)
        // React to synth state changes and rebuild the FX chain on the fly.
        $synth
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(20), scheduler: RunLoop.main)
            .sink { [weak self] state in
                self?.audio.applySynthState(state)
            }
            .store(in: &bag)
    }

    func start() {
        audio.start()
        midi.start()
        sampler.bind(audio: audio)
        mic.bind(audio: audio)
        audio.applySynthState(synth)
    }

    func applyPreset(id: String) {
        guard let preset = presets.preset(id: id) else { return }
        currentPresetID = id
        synth = preset.synth
    }

    func noteOn(pitch: NotePitch, velocity: Double = 1.0) {
        // If sustain had this note pending release, take it back.
        sustainedNotes.remove(pitch)
        guard heldNotes.insert(pitch).inserted else { return }
        let v = velocitySensitive ? max(0.15, min(1.0, velocity)) : 1.0
        audio.noteOn(pitch: pitch, velocity: v, synth: synth)
        if sequencer.isRecording {
            sequencer.recordNote(pitch: pitch)
        }
    }

    func noteOff(pitch: NotePitch) {
        guard heldNotes.remove(pitch) != nil else { return }
        if sustainHeld {
            // Keep ringing — only release on sustain-off.
            sustainedNotes.insert(pitch)
            return
        }
        audio.noteOff(pitch: pitch)
    }

    /// Toggle sustain pedal behavior. When sustain turns off, any pitches
    /// that were "held" only by sustain get released cleanly.
    func setSustain(_ on: Bool) {
        sustainHeld = on
        if !on {
            for pitch in sustainedNotes where !heldNotes.contains(pitch) {
                audio.noteOff(pitch: pitch)
            }
            sustainedNotes.removeAll()
        }
    }

    /// Cheap preview tap — used when the user taps a waveform / FX so they
    /// hear the timbre change. Plays middle C briefly.
    func previewCurrentTimbre() {
        let pitch = NotePitch(note: 0, octave: 4) // C4
        audio.noteOn(pitch: pitch, velocity: 0.6, synth: synth)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.audio.noteOff(pitch: pitch)
        }
    }

    func setPitchBend(_ value: Double) {
        pitchBend = max(-1, min(1, value))
        audio.setPitchBend(cents: pitchBend * 200)
    }

    func playDrum(index: Int) {
        audio.playDrum(index: index)
    }
}
