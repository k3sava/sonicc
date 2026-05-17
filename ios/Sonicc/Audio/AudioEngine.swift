import AVFoundation
import Foundation

/// Central audio host: owns AVAudioEngine, the polyphonic voice allocator,
/// the FX rack, and the master output chain. Mirrors the Web Audio signal
/// graph from index.html: voices → filter → fx → master gain → output.
final class AudioEngine {
    let engine = AVAudioEngine()
    let format: AVAudioFormat
    let voiceAllocator: VoiceAllocator
    let drumSynth: DrumSynth
    let mixer = AVAudioMixerNode()
    let fxRack: EffectsRack
    let masterGain = AVAudioMixerNode()

    /// Mic input is published here for the level meter view.
    var inputLevel: Float = 0

    private var pitchBendCents: Double = 0
    private var currentSynth: SynthState = .init()

    init() {
        let outFmt = engine.outputNode.outputFormat(forBus: 0)
        let sr = outFmt.sampleRate > 0 ? outFmt.sampleRate : 48_000
        self.format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2)!
        self.voiceAllocator = VoiceAllocator(format: format, maxVoices: 16)
        self.drumSynth = DrumSynth(format: format)
        self.fxRack = EffectsRack(format: format)
    }

    func start() {
        attach()
        connect()
        do {
            try engine.start()
        } catch {
            assertionFailure("AVAudioEngine start failed: \(error)")
        }
    }

    private func attach() {
        engine.attach(mixer)
        engine.attach(masterGain)
        for voice in voiceAllocator.voices {
            engine.attach(voice.sourceNode)
        }
        engine.attach(drumSynth.sourceNode)
        fxRack.attachAll(to: engine)
    }

    private func connect() {
        // voices + drum synth → mixer
        for voice in voiceAllocator.voices {
            engine.connect(voice.sourceNode, to: mixer, format: format)
        }
        engine.connect(drumSynth.sourceNode, to: mixer, format: format)
        // mixer → fx chain → master → output
        fxRack.wire(input: mixer, output: masterGain, in: engine, format: format)
        engine.connect(masterGain, to: engine.mainMixerNode, format: format)
    }

    // MARK: Synth state

    func applySynthState(_ state: SynthState) {
        currentSynth = state
        masterGain.outputVolume = Float(state.volume)
        masterGain.pan = Float(state.pan)
        fxRack.apply(state: state.fx)
        voiceAllocator.applyDefaults(state)
    }

    // MARK: Notes

    func noteOn(pitch: NotePitch, velocity: Double, synth: SynthState) {
        currentSynth = synth
        voiceAllocator.noteOn(
            pitch: pitch,
            velocity: velocity,
            synth: synth,
            pitchBendCents: pitchBendCents
        )
    }

    func noteOff(pitch: NotePitch) {
        voiceAllocator.noteOff(pitch: pitch)
    }

    func setPitchBend(cents: Double) {
        pitchBendCents = cents
        voiceAllocator.setPitchBend(cents: cents)
    }

    func playDrum(index: Int) {
        drumSynth.trigger(index: index)
    }

    /// Play a sample buffer (used by Sampler).
    func playSample(_ buffer: AVAudioPCMBuffer, gain: Float = 1.0) {
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: buffer.format)
        player.volume = gain
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                player.stop()
                self?.engine.detach(player)
            }
        }
        player.play()
    }

    // MARK: - Track render

    /// Active render-to-file session, if any.
    private var renderFile: AVAudioFile?
    private(set) var isRendering: Bool = false

    enum RenderFormat { case m4a, wav }

    /// Begin capturing everything coming out of the master bus to a new
    /// audio file. .m4a → AAC, small files for sharing; .wav → 16-bit PCM,
    /// uncompressed for DAW import.
    @discardableResult
    func startTrackRender(to url: URL, format: RenderFormat = .m4a) throws -> URL {
        let masterBus = engine.mainMixerNode.outputFormat(forBus: 0)
        let settings: [String: Any]
        switch format {
        case .m4a:
            settings = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: masterBus.sampleRate,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 192_000,
            ]
        case .wav:
            settings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: masterBus.sampleRate,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
            ]
        }
        let file = try AVAudioFile(forWriting: url, settings: settings)
        renderFile = file
        isRendering = true
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: masterBus) { [weak self] buf, _ in
            guard let self, let renderFile = self.renderFile else { return }
            do {
                try renderFile.write(from: buf)
            } catch {
                print("AudioEngine render write error: \(error)")
            }
        }
        return url
    }

    /// Close the file and remove the tap. Returns the rendered file URL
    /// if there was an active render.
    @discardableResult
    func stopTrackRender() -> URL? {
        guard isRendering else { return nil }
        engine.mainMixerNode.removeTap(onBus: 0)
        let url = renderFile?.url
        renderFile = nil
        isRendering = false
        return url
    }
}
