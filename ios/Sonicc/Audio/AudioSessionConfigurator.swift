import AVFoundation

enum AudioSessionConfigurator {
    static func configure() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP, .allowAirPlay]
            )
            try session.setPreferredIOBufferDuration(0.005)
            try session.setPreferredSampleRate(48_000)
            try session.setActive(true, options: [])
        } catch {
            assertionFailure("Audio session config failed: \(error)")
        }
    }
}
