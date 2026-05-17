import SwiftUI

/// Fills the breathing room between the transport bar and the keyboard.
/// Held notes drive a live chord recognizer: 1 note → big note name,
/// 2 notes → interval, 3+ notes → chord with quality (maj/min/dim/aug,
/// 7ths, sus, add). Below the headline, a recent-notes ticker remembers
/// the last 12 pitches played, so the player can see the last bar or two
/// of what they touched without looking down at the keys.
struct ChordReadout: View {
    @EnvironmentObject var app: AppState
    @State private var recent: [Recent] = []

    private struct Recent: Identifiable {
        let id = UUID()
        let pitch: NotePitch
        let at: Date
    }

    var body: some View {
        VStack(spacing: 14) {
            chordHeadline
            heldRow
            Spacer(minLength: 0)
            recentRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onChange(of: app.heldNotes) { _, new in
            // Track every new pitch as it gets held — the ticker grows
            // monotonically while you play.
            for pitch in new where !recent.contains(where: { $0.pitch == pitch }) {
                recent.append(Recent(pitch: pitch, at: .now))
                if recent.count > 12 { recent.removeFirst(recent.count - 12) }
            }
        }
    }

    // MARK: - Headline

    private var chordHeadline: some View {
        let label = ChordNamer.name(for: app.heldNotes)
        return Text(label.isEmpty ? "—" : label)
            .font(.system(size: 44, weight: .semibold, design: .serif))
            .foregroundStyle(label.isEmpty ? app.theme.textMuted.opacity(0.4) : app.theme.text)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .animation(.easeInOut(duration: 0.15), value: label)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Held pills

    private var heldRow: some View {
        let sorted = app.heldNotes.sorted { $0.midi < $1.midi }
        return HStack(spacing: 6) {
            if sorted.isEmpty {
                Text("press a key")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted.opacity(0.6))
            } else {
                ForEach(sorted, id: \.id) { p in
                    Text(p.label)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(app.theme.accent.opacity(0.15))
                        .foregroundStyle(app.theme.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recent ticker

    private var recentRow: some View {
        HStack(spacing: 0) {
            Text("LAST")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
                .padding(.trailing, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(recent.reversed()) { r in
                        Text(r.pitch.label)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .foregroundStyle(app.theme.textMuted)
                            .overlay(
                                Capsule().stroke(app.theme.border)
                            )
                    }
                }
            }
            Spacer(minLength: 0)
            if !recent.isEmpty {
                Button { recent.removeAll() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(app.theme.textMuted.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Chord naming

enum ChordNamer {
    /// Returns a chord/interval label for the given set of held notes.
    /// Empty if nothing is held.
    static func name(for pitches: Set<NotePitch>) -> String {
        let sorted = pitches.sorted { $0.midi < $1.midi }
        guard let lowest = sorted.first else { return "" }
        switch sorted.count {
        case 0: return ""
        case 1: return lowest.label
        case 2:
            let interval = sorted[1].midi - sorted[0].midi
            return "\(lowest.noteName) \(intervalName(interval))"
        default:
            return chordLabel(for: sorted) ?? sorted.map(\.noteName).joined(separator: " ")
        }
    }

    private static let qualities: [(intervals: Set<Int>, suffix: String)] = [
        ([0, 4, 7, 11], "maj7"),
        ([0, 4, 7, 10], "7"),
        ([0, 4, 7, 9],  "6"),
        ([0, 3, 7, 11], "minMaj7"),
        ([0, 3, 7, 10], "m7"),
        ([0, 3, 7, 9],  "m6"),
        ([0, 3, 6, 10], "m7♭5"),
        ([0, 3, 6, 9],  "dim7"),
        ([0, 4, 7, 2],  "add9"),
        ([0, 5, 7, 10], "7sus4"),
        ([0, 4, 7],     "maj"),
        ([0, 3, 7],     "m"),
        ([0, 3, 6],     "dim"),
        ([0, 4, 8],     "aug"),
        ([0, 2, 7],     "sus2"),
        ([0, 5, 7],     "sus4"),
    ]

    /// Try each pitch as the potential root and look for a known interval
    /// set match. First hit wins, ordered most-specific → most-generic.
    private static func chordLabel(for sorted: [NotePitch]) -> String? {
        let midis = sorted.map(\.midi)
        let pitchClasses = Set(midis.map { $0 % 12 })
        for root in midis {
            let relative = Set(pitchClasses.map { ($0 - (root % 12) + 12) % 12 })
            for quality in qualities {
                if relative.isSuperset(of: quality.intervals) {
                    let rootName = NoteNamer.name(for: root % 12)
                    return "\(rootName)\(quality.suffix)"
                }
            }
        }
        return nil
    }

    private static func intervalName(_ semitones: Int) -> String {
        switch semitones {
        case 0: return "unison"
        case 1: return "♭2"
        case 2: return "2"
        case 3: return "♭3"
        case 4: return "3"
        case 5: return "4"
        case 6: return "♭5"
        case 7: return "5"
        case 8: return "♭6"
        case 9: return "6"
        case 10: return "♭7"
        case 11: return "7"
        case 12: return "8va"
        default: return "+\(semitones)"
        }
    }
}

private enum NoteNamer {
    private static let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
    static func name(for pitchClass: Int) -> String {
        names[((pitchClass % 12) + 12) % 12]
    }
}

private extension NotePitch {
    var noteName: String { NoteNamer.name(for: note) }
}
