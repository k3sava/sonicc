import SwiftUI

/// Lists every SavedPattern in the on-disk library. Tap a row to load it
/// into the active sequencer; swipe to delete.
struct PatternLibrarySheet: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var library: PatternLibrary
    @Environment(\.dismiss) private var dismiss
    let onLoad: (SavedPattern) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if library.patterns.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(library.patterns) { p in
                            Button { onLoad(p) } label: { row(p) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { idx in
                            for i in idx { library.delete(library.patterns[i]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pattern Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(app.theme.textMuted)
            Text("No saved patterns yet")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
            Text("Build a pattern, tap Save.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(app.theme.textMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ p: SavedPattern) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(p.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(app.theme.text)
                Text("\(p.stepCount) steps · \(Int(p.bpm)) BPM" + (p.presetID.map { " · \($0)" } ?? ""))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
            }
            Spacer()
            Text(relativeDate(p.updatedAt))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func relativeDate(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: .now)
    }
}
