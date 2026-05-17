import SwiftUI

/// Lives between the performance bar and the keyboard. When notes are
/// held it shows a big serif chord name + held-note pills. When idle,
/// it shows a soft prompt + the recent-notes ticker.
struct ChordReadout: View {
    @EnvironmentObject var app: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var recent: [Recent] = []

    private struct Recent: Identifiable {
        let id = UUID()
        let pitch: NotePitch
        let at: Date
    }

    var body: some View {
        VStack(spacing: DS.Space.xs) {
            chordHeadline
            heldRow
            Spacer(minLength: 0)
            recentRow
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(app.theme.semantic.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(app.theme.semantic.hairline)
        )
        .onChange(of: app.heldNotes) { _, new in
            for pitch in new where !recent.contains(where: { $0.pitch == pitch }) {
                recent.append(Recent(pitch: pitch, at: .now))
                if recent.count > 16 { recent.removeFirst(recent.count - 16) }
            }
        }
    }

    private var chordHeadline: some View {
        let label = ChordNamer.name(for: app.heldNotes)
        return Text(label.isEmpty ? "play a chord" : label)
            .font(.system(.title2, design: .serif).weight(.semibold))
            .foregroundStyle(label.isEmpty ? app.theme.semantic.inkMuted : app.theme.semantic.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .animation(DS.ease(reduceMotion: reduceMotion, duration: 0.18), value: label)
            .frame(maxWidth: .infinity)
    }

    private var heldRow: some View {
        let sorted = app.heldNotes.sorted { $0.midi < $1.midi }
        return HStack(spacing: 4) {
            if sorted.isEmpty {
                EmptyView()
            } else {
                ForEach(sorted, id: \.id) { p in
                    Text(p.label)
                        .font(DS.font(.caption, weight: .medium, monospaced: true))
                        .padding(.horizontal, DS.Space.sm)
                        .padding(.vertical, DS.Space.xxs)
                        .background(Capsule().fill(app.theme.semantic.accentSoft))
                        .foregroundStyle(app.theme.semantic.accent)
                }
            }
        }
        .frame(minHeight: 22)
    }

    private var recentRow: some View {
        HStack(spacing: 0) {
            Text(recent.isEmpty ? "RECENT" : "LAST")
                .font(DS.font(.micro, weight: .semibold, monospaced: true))
                .tracking(1)
                .foregroundStyle(app.theme.semantic.inkMuted)
                .padding(.trailing, DS.Space.xs)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    if recent.isEmpty {
                        Text("history of what you play appears here")
                            .font(DS.font(.micro))
                            .foregroundStyle(app.theme.semantic.inkMuted.opacity(0.7))
                    } else {
                        ForEach(recent.reversed()) { r in
                            Text(r.pitch.label)
                                .font(DS.font(.micro, monospaced: true))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundStyle(app.theme.semantic.inkSoft)
                                .overlay(Capsule().stroke(app.theme.semantic.hairline))
                        }
                    }
                }
            }
            if !recent.isEmpty {
                Button { recent.removeAll(); Haptics.tap(.soft) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(app.theme.semantic.inkMuted.opacity(0.7))
                        .padding(.leading, DS.Space.xs)
                }
                .buttonStyle(.plain)
                .a11y("Clear recent notes")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chord naming

enum ChordNamer {
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
