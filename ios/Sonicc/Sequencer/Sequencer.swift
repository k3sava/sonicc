import Combine
import Foundation
import SwiftUI

/// Step sequencer with synth and drum layers. Mirrors the index.html
/// sequencer: 8/16/32/64 steps, swing, per-step velocity, recording mode.
@MainActor
final class Sequencer: ObservableObject {
    enum Layer: String { case synth, drum }
    enum StepSize: Int, CaseIterable, Identifiable {
        case s8 = 8, s16 = 16, s32 = 32, s64 = 64
        var id: Int { rawValue }
        var label: String { "\(rawValue)" }
    }

    @Published var stepCount: StepSize = .s16
    @Published var bpm: Double = 120
    @Published var swing: Double = 0 // 0..1
    @Published var isPlaying: Bool = false
    @Published var isRecording: Bool = false
    @Published var currentStep: Int = 0
    @Published var layer: Layer = .synth

    @Published var synthGrid: SequencerGrid = SequencerGrid(rows: 8, steps: 16)
    @Published var drumGrid: SequencerGrid = SequencerGrid(rows: 8, steps: 16)
    /// Per-step note pitches recorded by the user (only synth layer).
    @Published var synthNotes: [Int: NotePitch] = [:]

    private weak var audio: AudioEngine?
    private weak var state: AppState?
    private var timer: DispatchSourceTimer?
    private var lastTickHost: UInt64 = 0

    func bind(audio: AudioEngine, state: AppState) {
        self.audio = audio
        self.state = state
    }

    func setStepCount(_ size: StepSize) {
        stepCount = size
        synthGrid.resize(steps: size.rawValue)
        drumGrid.resize(steps: size.rawValue)
        synthNotes = synthNotes.filter { $0.key < size.rawValue }
        if currentStep >= size.rawValue { currentStep = 0 }
    }

    func play() {
        guard !isPlaying else { return }
        isPlaying = true
        currentStep = -1
        scheduleNextStep()
    }

    func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
    }

    func toggleRecord() {
        isRecording.toggle()
    }

    func toggleCell(row: Int, step: Int) {
        switch layer {
        case .synth: synthGrid.toggle(row: row, step: step)
        case .drum: drumGrid.toggle(row: row, step: step)
        }
    }

    func recordNote(pitch: NotePitch) {
        guard isPlaying else { return }
        // Latch the last-played note onto the *current* step's synth row.
        let step = max(0, currentStep)
        synthGrid.set(row: 0, step: step, on: true)
        synthNotes[step] = pitch
    }

    func clear() {
        synthGrid.clear()
        drumGrid.clear()
        synthNotes.removeAll()
    }

    private func scheduleNextStep() {
        let q = DispatchQueue.global(qos: .userInteractive)
        let t = DispatchSource.makeTimerSource(queue: q)
        let interval = stepInterval()
        t.schedule(deadline: .now() + interval, repeating: interval)
        t.setEventHandler { [weak self] in
            Task { @MainActor in self?.tick() }
        }
        t.resume()
        timer = t
    }

    private func stepInterval() -> DispatchTimeInterval {
        // 60 / bpm = beat seconds; 4 sixteenth-notes per beat
        let secondsPerStep = 60.0 / (bpm * 4.0)
        let micros = Int(secondsPerStep * 1_000_000)
        return .microseconds(micros)
    }

    private func tick() {
        guard isPlaying else { return }
        currentStep = (currentStep + 1) % stepCount.rawValue
        firePadsAt(step: currentStep)
    }

    private func firePadsAt(step: Int) {
        guard let audio else { return }
        // Synth layer: triggers a stored pitch if present and the row is lit.
        if synthGrid.anyOn(at: step) {
            let pitch = synthNotes[step] ?? NotePitch(note: 0, octave: 4)
            let synth = state?.synth ?? SynthState()
            audio.noteOn(pitch: pitch, velocity: 1, synth: synth)
            // Quick auto-noteoff so the sequencer doesn't hold notes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak audio] in
                audio?.noteOff(pitch: pitch)
            }
        }
        // Drum layer: each row triggers its drum index.
        for row in 0..<8 where drumGrid.isOn(row: row, step: step) {
            audio.playDrum(index: row)
        }
    }
}

struct SequencerGrid: Equatable {
    private(set) var rows: Int
    private(set) var steps: Int
    private(set) var cells: [[Bool]]

    init(rows: Int, steps: Int) {
        self.rows = rows
        self.steps = steps
        self.cells = Array(repeating: Array(repeating: false, count: steps), count: rows)
    }

    mutating func resize(steps newSteps: Int) {
        for i in 0..<rows {
            if newSteps > cells[i].count {
                cells[i].append(contentsOf: Array(repeating: false, count: newSteps - cells[i].count))
            } else {
                cells[i] = Array(cells[i].prefix(newSteps))
            }
        }
        steps = newSteps
    }

    mutating func toggle(row: Int, step: Int) {
        guard row >= 0, row < rows, step >= 0, step < steps else { return }
        cells[row][step].toggle()
    }

    mutating func set(row: Int, step: Int, on: Bool) {
        guard row >= 0, row < rows, step >= 0, step < steps else { return }
        cells[row][step] = on
    }

    func isOn(row: Int, step: Int) -> Bool {
        guard row >= 0, row < rows, step >= 0, step < steps else { return false }
        return cells[row][step]
    }

    func anyOn(at step: Int) -> Bool {
        guard step >= 0, step < steps else { return false }
        for row in 0..<rows where cells[row][step] { return true }
        return false
    }

    mutating func clear() {
        for i in 0..<rows {
            for j in 0..<steps { cells[i][j] = false }
        }
    }
}
