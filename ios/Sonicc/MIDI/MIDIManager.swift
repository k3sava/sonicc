import CoreMIDI
import Foundation

/// CoreMIDI input. Subscribes to all available sources and dispatches
/// note on/off, CC, and pitch-bend events. Channel 10 (zero-based 9) is
/// treated as drums and mapped via the General MIDI drum map.
@MainActor
final class MIDIManager {
    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private weak var audio: AudioEngine?
    private weak var sequencer: Sequencer?
    private weak var state: AppState?

    func bind(audio: AudioEngine, sequencer: Sequencer, state: AppState) {
        self.audio = audio
        self.sequencer = sequencer
        self.state = state
    }

    func start() {
        let name = "Sonicc" as CFString
        MIDIClientCreateWithBlock(name, &client) { _ in /* topology change */ }
        MIDIInputPortCreateWithProtocol(client, "Sonicc-in" as CFString, ._1_0, &inputPort) { [weak self] eventList, _ in
            self?.handle(eventList: eventList)
        }
        connectAllSources()
    }

    private func connectAllSources() {
        let count = MIDIGetNumberOfSources()
        var hasAny = false
        for i in 0..<count {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, src, nil)
            hasAny = true
        }
        Task { @MainActor in state?.midiConnected = hasAny }
    }

    private nonisolated func handle(eventList: UnsafePointer<MIDIEventList>) {
        var pkt = eventList.pointee.packet
        for _ in 0..<eventList.pointee.numPackets {
            let count = Int(pkt.wordCount)
            withUnsafePointer(to: pkt.words) { tuplePtr in
                tuplePtr.withMemoryRebound(to: UInt32.self, capacity: count) { wordsPtr in
                    for i in 0..<count { handleUMP(wordsPtr[i]) }
                }
            }
            pkt = withUnsafeMutablePointer(to: &pkt) { MIDIEventPacketNext($0).pointee }
        }
    }

    private nonisolated func handleUMP(_ word: UInt32) {
        // 32-bit UMP: status nibble in bits 20..23.
        let status = UInt8((word >> 16) & 0xFF)
        let kind = status & 0xF0
        let channel = status & 0x0F
        let data1 = UInt8((word >> 8) & 0x7F)
        let data2 = UInt8(word & 0x7F)
        Task { @MainActor in
            switch kind {
            case 0x90: // Note on
                if data2 == 0 { self.dispatchNoteOff(channel: channel, note: Int(data1)) }
                else { self.dispatchNoteOn(channel: channel, note: Int(data1), velocity: Int(data2)) }
            case 0x80:
                self.dispatchNoteOff(channel: channel, note: Int(data1))
            case 0xB0:
                self.dispatchCC(controller: Int(data1), value: Int(data2))
            case 0xE0:
                let bend = (Int(data2) << 7) | Int(data1)
                let normalized = (Double(bend) - 8192.0) / 8192.0
                self.state?.setPitchBend(normalized)
            default: break
            }
        }
    }

    private func dispatchNoteOn(channel: UInt8, note: Int, velocity: Int) {
        if channel == 9 {
            // GM drum map → our 8 drum indices
            audio?.playDrum(index: drumIndex(forMIDI: note))
        } else {
            let pitch = NotePitch.fromMIDI(note)
            state?.noteOn(pitch: pitch, velocity: Double(velocity) / 127.0)
        }
    }

    private func dispatchNoteOff(channel: UInt8, note: Int) {
        guard channel != 9 else { return }
        state?.noteOff(pitch: NotePitch.fromMIDI(note))
    }

    private func dispatchCC(controller: Int, value: Int) {
        let v = Double(value) / 127.0
        guard var synth = state?.synth else { return }
        switch controller {
        case 1: synth.filterFreq = 50 + v * 14_950       // mod wheel → cutoff
        case 7: synth.volume = v                          // volume
        case 74: synth.filterRes = 0.1 + v * 19.9         // resonance
        default: return
        }
        state?.synth = synth
    }

    private func drumIndex(forMIDI midi: Int) -> Int {
        switch midi {
        case 36: return 0 // kick
        case 38: return 1 // snare
        case 42: return 2 // hi-hat
        case 39: return 3 // clap
        case 45: return 4 // tom
        case 49: return 5 // crash
        case 56: return 6 // perc
        case 53, 54: return 7 // cowbell-ish
        default: return midi % 8
        }
    }
}
