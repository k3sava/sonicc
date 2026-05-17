import AVFoundation
import Foundation
import QuartzCore

/// Base for an effect that exposes a single in-graph audio node. Subclasses
/// decide what kind of AVAudioUnit drives the DSP — usually an EQ, Delay, or
/// Distortion unit — and modulate parameters via an LFO timer when enabled.
class FXNodeBase {
    let node: AVAudioNode
    private(set) var enabled: Bool = false

    init(node: AVAudioNode) {
        self.node = node
    }

    func attach(to engine: AVAudioEngine) {
        engine.attach(node)
    }

    func setEnabled(_ on: Bool) {
        enabled = on
        applyEnabled()
    }

    func applyEnabled() {}
}

/// Helper for periodic parameter modulation via CADisplayLink.
final class LFO {
    private var displayLink: CADisplayLink?
    private var phase: Double = 0
    private let frequency: Double
    private let tick: (Double) -> Void

    init(frequency: Double, _ tick: @escaping (Double) -> Void) {
        self.frequency = frequency
        self.tick = tick
    }

    func start() {
        stop()
        let target = LFOTarget(callback: { [weak self] in
            guard let self else { return }
            self.phase += self.frequency / 60.0 * 2.0 * .pi
            self.tick(sin(self.phase))
        })
        let link = CADisplayLink(target: target, selector: #selector(LFOTarget.tick))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

final class LFOTarget: NSObject {
    let callback: () -> Void
    init(callback: @escaping () -> Void) { self.callback = callback }
    @objc func tick() { callback() }
}

// MARK: - Chorus: short modulated delay

final class ChorusNode: FXNodeBase {
    private let unit: AVAudioUnitDelay
    private lazy var lfo = LFO(frequency: 0.5) { [weak self] s in
        guard let self else { return }
        let t = 0.012 + s * 0.004
        self.unit.delayTime = TimeInterval(t)
    }

    init(format: AVAudioFormat) {
        let d = AVAudioUnitDelay()
        d.wetDryMix = 0
        d.feedback = 0
        d.delayTime = 0.012
        d.lowPassCutoff = 8_000
        self.unit = d
        super.init(node: d)
    }

    override func applyEnabled() {
        unit.wetDryMix = enabled ? 40 : 0
        if enabled { lfo.start() } else { lfo.stop() }
    }
}

// MARK: - Phaser: modulated allpass-ish, via resonant LPF sweep

final class PhaserNode: FXNodeBase {
    private let eq: AVAudioUnitEQ
    private lazy var lfo = LFO(frequency: 0.4) { [weak self] s in
        guard let self, let b = self.eq.bands.first else { return }
        b.frequency = Float(800 + s * 700)
    }

    init(format: AVAudioFormat) {
        let e = AVAudioUnitEQ(numberOfBands: 1)
        if let b = e.bands.first {
            b.filterType = .resonantLowPass
            b.frequency = 1500
            b.bandwidth = 1
            b.bypass = true
        }
        self.eq = e
        super.init(node: e)
    }

    override func applyEnabled() {
        if let b = eq.bands.first { b.bypass = !enabled }
        if enabled { lfo.start() } else { lfo.stop() }
    }
}

// MARK: - Compressor: soft-clip emulation via distortion preset at low gain

final class CompressorNode: FXNodeBase {
    private let unit: AVAudioUnitDistortion

    init(format: AVAudioFormat) {
        let u = AVAudioUnitDistortion()
        u.loadFactoryPreset(.multiDistortedSquared)
        u.preGain = -8
        u.wetDryMix = 0
        self.unit = u
        super.init(node: u)
    }

    override func applyEnabled() {
        unit.wetDryMix = enabled ? 25 : 0
    }
}

// MARK: - Bitcrusher: heavy sample-rate-decimation preset

final class BitcrusherNode: FXNodeBase {
    private let unit: AVAudioUnitDistortion

    init(format: AVAudioFormat) {
        let u = AVAudioUnitDistortion()
        u.loadFactoryPreset(.multiDecimated1)
        u.preGain = 0
        u.wetDryMix = 0
        self.unit = u
        super.init(node: u)
    }

    override func applyEnabled() {
        unit.wetDryMix = enabled ? 60 : 0
    }
}

// MARK: - Tremolo: EQ-band gain modulation at ~5 Hz

final class TremoloNode: FXNodeBase {
    private let eq: AVAudioUnitEQ
    private lazy var lfo = LFO(frequency: 5.0) { [weak self] s in
        guard let self, let b = self.eq.bands.first else { return }
        b.gain = Float(s * 6)
    }

    init(format: AVAudioFormat) {
        let e = AVAudioUnitEQ(numberOfBands: 1)
        if let b = e.bands.first {
            b.filterType = .parametric
            b.frequency = 1_000
            b.bandwidth = 4
            b.gain = 0
            b.bypass = true
        }
        self.eq = e
        super.init(node: e)
    }

    override func applyEnabled() {
        if let b = eq.bands.first { b.bypass = !enabled }
        if enabled { lfo.start() } else { lfo.stop() }
    }
}

// MARK: - Flanger: very short modulated delay with feedback

final class FlangerNode: FXNodeBase {
    private let unit: AVAudioUnitDelay
    private lazy var lfo = LFO(frequency: 0.3) { [weak self] s in
        guard let self else { return }
        let t = 0.004 + s * 0.002
        self.unit.delayTime = TimeInterval(t)
    }

    init(format: AVAudioFormat) {
        let d = AVAudioUnitDelay()
        d.wetDryMix = 0
        d.feedback = 65
        d.delayTime = 0.004
        self.unit = d
        super.init(node: d)
    }

    override func applyEnabled() {
        unit.wetDryMix = enabled ? 50 : 0
        if enabled { lfo.start() } else { lfo.stop() }
    }
}

// MARK: - Autowah: resonant LPF sweep at ~2 Hz

final class AutowahNode: FXNodeBase {
    private let eq: AVAudioUnitEQ
    private lazy var lfo = LFO(frequency: 2.0) { [weak self] s in
        guard let self, let b = self.eq.bands.first else { return }
        b.frequency = Float(800 + s * 600)
    }

    init(format: AVAudioFormat) {
        let e = AVAudioUnitEQ(numberOfBands: 1)
        if let b = e.bands.first {
            b.filterType = .resonantLowPass
            b.frequency = 800
            b.bandwidth = 1
            b.bypass = true
        }
        self.eq = e
        super.init(node: e)
    }

    override func applyEnabled() {
        if let b = eq.bands.first { b.bypass = !enabled }
        if enabled { lfo.start() } else { lfo.stop() }
    }
}
