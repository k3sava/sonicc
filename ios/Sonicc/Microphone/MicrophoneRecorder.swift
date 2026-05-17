import AVFoundation
import Combine
import Foundation

/// Microphone capture using AVAudioEngine's input node. Streams the input
/// to a level meter and accumulates frames into an AVAudioPCMBuffer that
/// can be handed to the sampler or written to disk.
@MainActor
final class MicrophoneRecorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var elapsed: TimeInterval = 0
    @Published var level: Float = 0
    @Published var lastBuffer: AVAudioPCMBuffer?

    private weak var audio: AudioEngine?
    private var inputNode: AVAudioInputNode?
    private var inputFormat: AVAudioFormat?
    private var accumulator: AVAudioPCMBuffer?
    private var startedAt: Date?
    private var timer: Timer?

    func bind(audio: AudioEngine) {
        self.audio = audio
    }

    func start() {
        guard let audio else { return }
        let input = audio.engine.inputNode
        let format = input.outputFormat(forBus: 0)
        inputNode = input
        inputFormat = format
        // Preallocate ~60 seconds of capacity.
        let cap = AVAudioFrameCount(format.sampleRate * 60.0)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: cap) else { return }
        accumulator = buffer
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
            self?.handleTap(buf)
        }
        isRecording = true
        elapsed = 0
        startedAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let started = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(started)
            }
        }
    }

    func stop() {
        inputNode?.removeTap(onBus: 0)
        isRecording = false
        timer?.invalidate()
        timer = nil
        lastBuffer = accumulator
    }

    func sendToSampler(_ sampler: SamplerEngine) {
        if let buf = lastBuffer { sampler.loadBuffer(buf) }
    }

    func clear() {
        lastBuffer = nil
        accumulator = nil
        elapsed = 0
    }

    func preview() {
        guard let audio, let buf = lastBuffer else { return }
        audio.playSample(buf)
    }

    func writeToDisk() throws -> URL {
        guard let buf = lastBuffer else { throw NSError(domain: "mic", code: -1) }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("recording-\(Int(Date().timeIntervalSince1970)).caf")
        let file = try AVAudioFile(forWriting: url, settings: buf.format.settings)
        try file.write(from: buf)
        return url
    }

    private nonisolated func handleTap(_ buf: AVAudioPCMBuffer) {
        // Cheap RMS for the meter.
        var rms: Float = 0
        if let chan = buf.floatChannelData?[0] {
            let n = Int(buf.frameLength)
            var sum: Float = 0
            for i in 0..<n { sum += chan[i] * chan[i] }
            rms = n > 0 ? sqrt(sum / Float(n)) : 0
        }
        Task { @MainActor in
            self.level = min(1, rms * 4)
            self.append(buf)
        }
    }

    private func append(_ buf: AVAudioPCMBuffer) {
        guard let acc = accumulator else { return }
        let needed = acc.frameLength + buf.frameLength
        if needed > acc.frameCapacity { return } // reached preallocated max
        let copyCount = Int(buf.frameLength)
        let channels = Int(acc.format.channelCount)
        if let dst = acc.floatChannelData, let src = buf.floatChannelData {
            let writeOffset = Int(acc.frameLength)
            for ch in 0..<min(channels, Int(buf.format.channelCount)) {
                for i in 0..<copyCount {
                    dst[ch][writeOffset + i] = src[ch][i]
                }
            }
        }
        acc.frameLength = needed
    }
}
