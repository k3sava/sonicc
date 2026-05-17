import Foundation

struct NotePitch: Hashable, Identifiable {
    let note: Int    // 0..11 (C..B)
    let octave: Int  // 0..8

    static let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var id: Int { note + octave * 12 }
    var midi: Int { 12 + note + octave * 12 } // standard MIDI: C0=12
    var name: String { Self.names[note] }
    var label: String { "\(name)\(octave)" }
    var isBlack: Bool { name.contains("#") }
    var frequency: Double {
        // A4 (note 9, octave 4) = 440
        let semitonesFromA4 = (octave - 4) * 12 + (note - 9)
        return 440.0 * pow(2.0, Double(semitonesFromA4) / 12.0)
    }

    static func fromMIDI(_ midi: Int) -> NotePitch {
        let n = midi - 12
        return NotePitch(note: ((n % 12) + 12) % 12, octave: n / 12)
    }
}
