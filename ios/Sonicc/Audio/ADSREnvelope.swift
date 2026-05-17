import Foundation

/// Sample-accurate ADSR envelope, used per-voice.
///
/// State machine: idle → attack → decay → sustain → release → idle.
struct ADSREnvelope {
    enum Stage { case idle, attack, decay, sustain, release }

    private let sampleRate: Double
    private(set) var stage: Stage = .idle
    private var level: Double = 0
    private var attackInc: Double = 0
    private var decayDec: Double = 0
    private var sustainLevel: Double = 0
    private var releaseDec: Double = 0
    private var velocity: Double = 1

    var isActive: Bool { stage != .idle }

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }

    mutating func configure(attack: Double, decay: Double, sustain: Double, release: Double, velocity: Double) {
        self.velocity = max(0, min(1, velocity))
        let a = max(0.0005, attack)
        let d = max(0.005, decay)
        let r = max(0.005, release)
        attackInc = 1.0 / (a * sampleRate)
        decayDec = (1.0 - sustain) / (d * sampleRate)
        sustainLevel = max(0, min(1, sustain))
        releaseDec = 1.0 / (r * sampleRate)
    }

    mutating func noteOn() {
        stage = .attack
    }

    mutating func noteOff() {
        if stage != .idle { stage = .release }
    }

    mutating func silence() {
        stage = .idle
        level = 0
    }

    mutating func tick() -> Double {
        switch stage {
        case .idle:
            return 0
        case .attack:
            level += attackInc
            if level >= 1.0 { level = 1.0; stage = .decay }
        case .decay:
            level -= decayDec
            if level <= sustainLevel { level = sustainLevel; stage = .sustain }
        case .sustain:
            level = sustainLevel
        case .release:
            level -= level * releaseDec
            if level <= 0.0001 { level = 0; stage = .idle }
        }
        return level * velocity
    }
}
