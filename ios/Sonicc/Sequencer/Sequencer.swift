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

    /// Rhythmic subdivision of a quarter note. 4 = sixteenth, 6 = triplet
    /// sixteenth, 3 = eighth triplet, 2 = eighth. Multiplies the tick rate
    /// per quarter.
    enum Subdivision: String, CaseIterable, Identifiable {
        case eighth      = "1/8"
        case eighthT     = "1/8t"
        case sixteenth   = "1/16"
        case sixteenthT  = "1/16t"
        case thirtySec   = "1/32"

        var id: String { rawValue }
        var stepsPerQuarter: Double {
            switch self {
            case .eighth: return 2
            case .eighthT: return 3
            case .sixteenth: return 4
            case .sixteenthT: return 6
            case .thirtySec: return 8
            }
        }
    }

    @Published var stepCount: StepSize = .s16
    @Published var subdivision: Subdivision = .sixteenth
    @Published var bpm: Double = 120
    @Published var swing: Double = 0 // 0..1
    @Published var isPlaying: Bool = false
    @Published var chainEnabled: Bool = false
    @Published var activeSlot: Int = 0           // 0..3 → A/B/C/D
    @Published var slotSnapshots: [Data?] = Array(repeating: nil, count: 4)
    @Published var isRecording: Bool = false
    @Published var currentStep: Int = 0
    @Published var layer: Layer = .synth

    @Published var synthGrid: SequencerGrid = SequencerGrid(rows: 8, steps: 16)
    @Published var drumGrid: SequencerGrid = SequencerGrid(rows: 8, steps: 16)
    /// Per-step note pitches recorded by the user via real-time record.
    @Published var synthNotes: [Int: NotePitch] = [:]
    /// One pitch per row of the synth grid — top row = highest, bottom row
    /// = lowest. Default is a C major scale across one octave.
    @Published var synthRowPitches: [NotePitch] = [
        NotePitch(note: 0,  octave: 5), // C5
        NotePitch(note: 11, octave: 4), // B4
        NotePitch(note: 9,  octave: 4), // A4
        NotePitch(note: 7,  octave: 4), // G4
        NotePitch(note: 5,  octave: 4), // F4
        NotePitch(note: 4,  octave: 4), // E4
        NotePitch(note: 2,  octave: 4), // D4
        NotePitch(note: 0,  octave: 4), // C4
    ]

    private weak var audio: AudioEngine?
    private weak var state: AppState?
    private var timer: DispatchSourceTimer?
    private var lastTickHost: UInt64 = 0

    func bind(audio: AudioEngine, state: AppState) {
        self.audio = audio
        self.state = state
        restoreWorking()
        restoreSlots()
    }

    // MARK: - Pattern slots (song arrangement)

    private static let slotsKey = "sonicc.sequencer.slots"
    private static let chainKey = "sonicc.sequencer.chainEnabled"
    private static let activeSlotKey = "sonicc.sequencer.activeSlot"

    /// Save the current sequencer state into the given slot (0..3 = A..D).
    func saveSlot(_ index: Int) {
        guard slotSnapshots.indices.contains(index) else { return }
        let snap = snapshot(named: slotLetter(index))
        slotSnapshots[index] = try? JSONEncoder().encode(snap)
        persistSlots()
    }

    /// Load the snapshot in the given slot into the live sequencer.
    /// If the slot is empty, this is a no-op.
    func loadSlot(_ index: Int) {
        guard slotSnapshots.indices.contains(index),
              let data = slotSnapshots[index],
              let snap = try? JSONDecoder().decode(SavedPattern.self, from: data) else {
            return
        }
        restore(snap)
        activeSlot = index
        UserDefaults.standard.set(index, forKey: Self.activeSlotKey)
    }

    /// Wipe the snapshot in the given slot.
    func clearSlot(_ index: Int) {
        guard slotSnapshots.indices.contains(index) else { return }
        slotSnapshots[index] = nil
        persistSlots()
    }

    func slotIsEmpty(_ index: Int) -> Bool {
        slotSnapshots.indices.contains(index) ? slotSnapshots[index] == nil : true
    }

    static func slotLetter(_ index: Int) -> String {
        ["A", "B", "C", "D"][max(0, min(3, index))]
    }
    func slotLetter(_ index: Int) -> String { Self.slotLetter(index) }

    /// In chain mode, after a full pattern loop wraps to step 0, advance
    /// to the next populated slot. If no other slot has data, stay put.
    func advanceChainIfNeeded() {
        guard chainEnabled else { return }
        // Find next populated slot, wrapping around. Skip the current one
        // unless it's the only populated slot.
        let total = slotSnapshots.count
        for offset in 1...total {
            let idx = (activeSlot + offset) % total
            if !slotIsEmpty(idx) {
                if idx != activeSlot {
                    loadSlot(idx)
                }
                return
            }
        }
    }

    func setChain(_ on: Bool) {
        chainEnabled = on
        UserDefaults.standard.set(on, forKey: Self.chainKey)
    }

    private func persistSlots() {
        // Store snapshots as [base64?] for UserDefaults compatibility.
        let encoded = slotSnapshots.map { $0?.base64EncodedString() ?? "" }
        UserDefaults.standard.set(encoded, forKey: Self.slotsKey)
    }

    private func restoreSlots() {
        if let strings = UserDefaults.standard.array(forKey: Self.slotsKey) as? [String] {
            slotSnapshots = strings.map { $0.isEmpty ? nil : Data(base64Encoded: $0) }
            // Pad/truncate to exactly 4
            while slotSnapshots.count < 4 { slotSnapshots.append(nil) }
            if slotSnapshots.count > 4 { slotSnapshots = Array(slotSnapshots.prefix(4)) }
        }
        chainEnabled = UserDefaults.standard.bool(forKey: Self.chainKey)
        activeSlot = max(0, min(3, UserDefaults.standard.integer(forKey: Self.activeSlotKey)))
    }

    // MARK: - Auto-save working pattern (never lose work)

    private static let workingKey = "sonicc.sequencer.working"

    /// Save the current sequencer state to UserDefaults under a single key.
    /// Called on every cell toggle, layer change, step-size change.
    func saveWorking() {
        let snapshot = snapshot(named: "_working")
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.workingKey)
        }
    }

    /// Restore the last-saved working pattern, if any. Called from bind().
    private func restoreWorking() {
        guard let data = UserDefaults.standard.data(forKey: Self.workingKey),
              let snapshot = try? JSONDecoder().decode(SavedPattern.self, from: data) else {
            return
        }
        restore(snapshot)
    }

    func setStepCount(_ size: StepSize) {
        stepCount = size
        synthGrid.resize(steps: size.rawValue)
        drumGrid.resize(steps: size.rawValue)
        synthNotes = synthNotes.filter { $0.key < size.rawValue }
        if currentStep >= size.rawValue { currentStep = 0 }
        saveWorking()
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
        saveWorking()
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
        saveWorking()
    }

    // MARK: - Snapshot / restore

    /// Serialize all pattern state for PatternLibrary persistence.
    func snapshot(named name: String) -> SavedPattern {
        SavedPattern(
            name: name,
            bpm: bpm,
            swing: swing,
            stepCount: stepCount.rawValue,
            synthCells: synthGrid.cells,
            drumCells: drumGrid.cells,
            synthNotes: synthNotes.mapValues { NotePitchSnapshot(note: $0.note, octave: $0.octave) },
            presetID: state?.currentPresetID,
            themeID: state?.theme.id
        )
    }

    /// Replace current sequencer state from a SavedPattern.
    func restore(_ p: SavedPattern) {
        bpm = p.bpm
        swing = p.swing
        if let size = StepSize(rawValue: p.stepCount) {
            stepCount = size
        }
        synthGrid = SequencerGrid(rows: 8, steps: p.stepCount, cells: p.synthCells)
        drumGrid = SequencerGrid(rows: 8, steps: p.stepCount, cells: p.drumCells)
        synthNotes = p.synthNotes.reduce(into: [:]) { acc, kv in
            acc[kv.key] = NotePitch(note: kv.value.note, octave: kv.value.octave)
        }
        if let presetID = p.presetID { state?.applyPreset(id: presetID) }
    }

    private func scheduleNextStep() {
        let q = DispatchQueue.global(qos: .userInteractive)
        let t = DispatchSource.makeTimerSource(queue: q)
        // Schedule a *non-repeating* fire; each tick reschedules so the swing
        // offset (which alternates per step) is applied to the next interval.
        t.schedule(deadline: .now() + nextStepInterval())
        t.setEventHandler { [weak self] in
            Task { @MainActor in self?.tick() }
        }
        t.resume()
        timer = t
    }

    private func nextStepInterval() -> DispatchTimeInterval {
        // stepsPerQuarter from the active Subdivision; e.g. 4 for sixteenth,
        // 6 for sixteenth-triplet. So secondsPerStep = 60 / (bpm * sPQ).
        let secondsPerStep = 60.0 / (bpm * subdivision.stepsPerQuarter)
        let isOffBeat = (currentStep + 1) % 2 != 0
        let factor = isOffBeat ? (1.0 + swing) : (1.0 - swing)
        let micros = Int(secondsPerStep * factor * 1_000_000)
        return .microseconds(max(1, micros))
    }

    private func tick() {
        guard isPlaying else { return }
        let next = (currentStep + 1) % stepCount.rawValue
        // If the loop wraps and chain mode is on, jump to the next slot.
        if next == 0 && currentStep != -1 {
            advanceChainIfNeeded()
        }
        currentStep = next
        firePadsAt(step: currentStep)
        scheduleNextStep()
    }

    private func firePadsAt(step: Int) {
        guard let audio else { return }
        let synth = state?.synth ?? SynthState()
        // Synth layer: every lit row triggers its own pitch — top row is
        // the highest, bottom is the lowest. If a real-time recording put
        // a specific pitch on this step, that overrides the row mapping
        // (only when the bottom row is the one lit, matching the recorder).
        for row in 0..<8 where synthGrid.isOn(row: row, step: step) {
            let pitch: NotePitch
            if row == 0, let recorded = synthNotes[step] {
                pitch = recorded
            } else {
                pitch = row < synthRowPitches.count ? synthRowPitches[row] : NotePitch(note: 0, octave: 4)
            }
            audio.noteOn(pitch: pitch, velocity: 0.9, synth: synth)
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

    /// Restore from a saved snapshot. Pads / truncates rows to expected size.
    init(rows: Int, steps: Int, cells: [[Bool]]) {
        self.rows = rows
        self.steps = steps
        var normalized: [[Bool]] = []
        for r in 0..<rows {
            let source = r < cells.count ? cells[r] : []
            var row = source
            if row.count < steps {
                row.append(contentsOf: Array(repeating: false, count: steps - row.count))
            } else if row.count > steps {
                row = Array(row.prefix(steps))
            }
            normalized.append(row)
        }
        self.cells = normalized
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
