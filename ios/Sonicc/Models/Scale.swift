import Foundation

/// Musical scale model. Scales are sets of pitch classes (0..11) relative
/// to a tonic. Use `Scale.contains(pitchClass:)` to check if any note is
/// "in scale" for the chosen root + mode — what powers the keyboard's
/// scale-tinted highlight.
struct Scale: Hashable, Identifiable {
    let id: String
    let displayName: String
    /// Semitone intervals from the root.
    let intervals: [Int]

    func pitchClasses(root: Int) -> Set<Int> {
        Set(intervals.map { ((root + $0) % 12 + 12) % 12 })
    }

    static let major       = Scale(id: "major",       displayName: "Major",       intervals: [0, 2, 4, 5, 7, 9, 11])
    static let minor       = Scale(id: "minor",       displayName: "Minor",       intervals: [0, 2, 3, 5, 7, 8, 10])
    static let harmMinor   = Scale(id: "harm-minor",  displayName: "Harm. Minor", intervals: [0, 2, 3, 5, 7, 8, 11])
    static let melMinor    = Scale(id: "mel-minor",   displayName: "Mel. Minor",  intervals: [0, 2, 3, 5, 7, 9, 11])
    static let pentMajor   = Scale(id: "pent-major",  displayName: "Pentatonic",  intervals: [0, 2, 4, 7, 9])
    static let pentMinor   = Scale(id: "pent-minor",  displayName: "Min. Pent.",  intervals: [0, 3, 5, 7, 10])
    static let blues       = Scale(id: "blues",       displayName: "Blues",       intervals: [0, 3, 5, 6, 7, 10])
    static let dorian      = Scale(id: "dorian",      displayName: "Dorian",      intervals: [0, 2, 3, 5, 7, 9, 10])
    static let phrygian    = Scale(id: "phrygian",    displayName: "Phrygian",    intervals: [0, 1, 3, 5, 7, 8, 10])
    static let lydian      = Scale(id: "lydian",      displayName: "Lydian",      intervals: [0, 2, 4, 6, 7, 9, 11])
    static let mixolydian  = Scale(id: "mixolydian",  displayName: "Mixolydian",  intervals: [0, 2, 4, 5, 7, 9, 10])
    static let chromatic   = Scale(id: "chromatic",   displayName: "Chromatic",   intervals: Array(0..<12))

    static let all: [Scale] = [
        .major, .minor, .pentMajor, .pentMinor, .blues,
        .dorian, .phrygian, .lydian, .mixolydian,
        .harmMinor, .melMinor, .chromatic,
    ]
}

/// Active selection: a tonic (0..11) + a Scale. Default = C Chromatic
/// (every note is in scale → no highlight).
struct ScaleSelection: Hashable {
    var root: Int        // 0..11
    var scale: Scale

    static let none = ScaleSelection(root: 0, scale: .chromatic)

    var displayName: String {
        let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
        return "\(names[root]) \(scale.displayName)"
    }

    func contains(pitchClass: Int) -> Bool {
        scale.pitchClasses(root: root).contains(((pitchClass % 12) + 12) % 12)
    }
}
