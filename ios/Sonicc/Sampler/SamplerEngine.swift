import AVFoundation
import Combine
import Foundation

/// 4-pad sample player. Each pad holds an AudioBuffer; pads can be assigned
/// from the mic recorder or by slicing the active buffer with start/end
/// percent markers (mirroring the Web Audio sampler in index.html).
@MainActor
final class SamplerEngine: ObservableObject {
    @Published var pads: [AVAudioPCMBuffer?] = Array(repeating: nil, count: 4)
    @Published var currentBuffer: AVAudioPCMBuffer?
    @Published var sliceStart: Double = 0   // 0..1
    @Published var sliceEnd: Double = 1     // 0..1
    @Published var loop: Bool = false

    private weak var audio: AudioEngine?

    func bind(audio: AudioEngine) {
        self.audio = audio
    }

    func loadBuffer(_ buffer: AVAudioPCMBuffer) {
        currentBuffer = buffer
        sliceStart = 0
        sliceEnd = 1
    }

    func sliceToPad(_ index: Int) {
        guard index >= 0, index < 4, let buf = currentBuffer else { return }
        let total = Int(buf.frameLength)
        let start = max(0, min(total - 1, Int(Double(total) * sliceStart)))
        let end = max(start + 1, min(total, Int(Double(total) * sliceEnd)))
        let length = end - start
        guard let format = buf.format.copy() as? AVAudioFormat else { return }
        guard let dst = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length)) else { return }
        dst.frameLength = AVAudioFrameCount(length)
        if let srcCh = buf.floatChannelData, let dstCh = dst.floatChannelData {
            let channels = Int(buf.format.channelCount)
            for ch in 0..<channels {
                for i in 0..<length {
                    dstCh[ch][i] = srcCh[ch][start + i]
                }
            }
        }
        pads[index] = dst
    }

    func playPad(_ index: Int) {
        guard let audio, let buf = pads[index] else { return }
        audio.playSample(buf)
    }

    func clearPad(_ index: Int) {
        pads[index] = nil
    }
}
