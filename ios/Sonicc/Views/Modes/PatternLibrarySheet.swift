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
            miniGrid(for: p)
                .frame(width: 60, height: 40)
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

    /// Tiny visualisation of a saved pattern — synth on top, drum on bottom.
    private func miniGrid(for p: SavedPattern) -> some View {
        let merged = mergeCells(p.synthCells, p.drumCells)
        return GeometryReader { geo in
            let stepCount = max(1, p.stepCount)
            let rowCount = max(1, merged.count)
            let cellW = geo.size.width / CGFloat(stepCount)
            let cellH = geo.size.height / CGFloat(rowCount)
            Canvas { context, _ in
                for (rIdx, row) in merged.enumerated() {
                    for (sIdx, on) in row.enumerated() where on {
                        let rect = CGRect(
                            x: CGFloat(sIdx) * cellW + 0.5,
                            y: CGFloat(rIdx) * cellH + 0.5,
                            width: max(1, cellW - 1),
                            height: max(1, cellH - 1)
                        )
                        context.fill(Path(rect), with: .color(app.theme.accent))
                    }
                }
            }
            .background(app.theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(app.theme.border))
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    /// Stack the synth and drum grids into one rendering — synth rows first,
    /// then a thin spacer row, then drum rows.
    private func mergeCells(_ a: [[Bool]], _ b: [[Bool]]) -> [[Bool]] {
        var out = a
        // Spacer row: skip — instead just append b directly.
        out.append(contentsOf: b)
        return out
    }

    private func relativeDate(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: .now)
    }
}
