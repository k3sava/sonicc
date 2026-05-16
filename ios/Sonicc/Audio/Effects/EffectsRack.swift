import AVFoundation
import Foundation

/// Holds every FX node and routes signal through them in a fixed order.
/// Toggling an effect just sets its wet/dry mix (or bypass) to zero — it
/// stays in the graph to avoid clicks/pops when flipped during playback.
final class EffectsRack {
    private let format: AVAudioFormat

    let reverb = AVAudioUnitReverb()
    let delay = AVAudioUnitDelay()
    let distortion = AVAudioUnitDistortion()
    let lofi = AVAudioUnitEQ(numberOfBands: 1)
    let eq = AVAudioUnitEQ(numberOfBands: 3)

    let chorus: ChorusNode
    let phaser: PhaserNode
    let compressor: CompressorNode
    let bitcrusher: BitcrusherNode
    let tremolo: TremoloNode
    let flanger: FlangerNode
    let autowah: AutowahNode

    init(format: AVAudioFormat) {
        self.format = format
        chorus = ChorusNode(format: format)
        phaser = PhaserNode(format: format)
        compressor = CompressorNode(format: format)
        bitcrusher = BitcrusherNode(format: format)
        tremolo = TremoloNode(format: format)
        flanger = FlangerNode(format: format)
        autowah = AutowahNode(format: format)
        configureBuiltins()
    }

    func attachAll(to engine: AVAudioEngine) {
        for n in [reverb, delay, distortion, lofi, eq] {
            engine.attach(n)
        }
        chorus.attach(to: engine)
        phaser.attach(to: engine)
        compressor.attach(to: engine)
        bitcrusher.attach(to: engine)
        tremolo.attach(to: engine)
        flanger.attach(to: engine)
        autowah.attach(to: engine)
    }

    /// Wire input → fx chain → output.
    func wire(input: AVAudioNode, output: AVAudioNode, in engine: AVAudioEngine, format: AVAudioFormat) {
        var prev: AVAudioNode = input
        let chain: [AVAudioNode] = [
            compressor.node, eq, lofi, distortion, bitcrusher.node,
            chorus.node, flanger.node, phaser.node, autowah.node,
            tremolo.node, delay, reverb,
        ]
        for node in chain {
            engine.connect(prev, to: node, format: format)
            prev = node
        }
        engine.connect(prev, to: output, format: format)
    }

    func apply(state: SynthState.FXState) {
        reverb.wetDryMix = state.reverb ? 35 : 0
        delay.wetDryMix = state.delay ? 30 : 0
        distortion.wetDryMix = state.distortion ? 50 : 0
        if let band = lofi.bands.first { band.bypass = !state.lofi }
        for band in eq.bands { band.bypass = !state.eq }
        chorus.setEnabled(state.chorus)
        phaser.setEnabled(state.phaser)
        compressor.setEnabled(state.compressor)
        bitcrusher.setEnabled(state.bitcrusher)
        tremolo.setEnabled(state.tremolo)
        flanger.setEnabled(state.flanger)
        autowah.setEnabled(state.autowah)
    }

    private func configureBuiltins() {
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 0

        delay.delayTime = 0.32
        delay.feedback = 35
        delay.lowPassCutoff = 6_000
        delay.wetDryMix = 0

        distortion.loadFactoryPreset(.multiDistortedFunk)
        distortion.wetDryMix = 0
        distortion.preGain = -2

        if let band = lofi.bands.first {
            band.filterType = .lowPass
            band.frequency = 2_000
            band.bandwidth = 1
            band.bypass = true
        }
        let eqBands = eq.bands
        if eqBands.count >= 3 {
            eqBands[0].filterType = .lowShelf
            eqBands[0].frequency = 320
            eqBands[0].gain = 0
            eqBands[1].filterType = .parametric
            eqBands[1].frequency = 1_000
            eqBands[1].bandwidth = 1
            eqBands[1].gain = 0
            eqBands[2].filterType = .highShelf
            eqBands[2].frequency = 3_200
            eqBands[2].gain = 0
            for b in eqBands { b.bypass = true }
        }
    }
}
