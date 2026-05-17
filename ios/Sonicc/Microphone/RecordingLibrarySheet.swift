import SwiftUI

/// Lists saved mic recordings. Tap to play, swipe to delete, long-press to share.
struct RecordingLibrarySheet: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var library: RecordingLibrary
    @Environment(\.dismiss) private var dismiss
    let onPlay: (SavedRecording) -> Void
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if library.recordings.isEmpty {
                    empty
                } else {
                    List {
                        ForEach(library.recordings) { r in
                            Button { onPlay(r) } label: { row(r) }
                                .buttonStyle(.plain)
                                .swipeActions(allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        library.delete(r)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        shareURL = r.url
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: Binding(get: { shareURL.map { URLWrapper(url: $0) } },
                              set: { shareURL = $0?.url })) { wrapper in
            ShareSheet(items: [wrapper.url])
        }
        .presentationDetents([.medium, .large])
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(app.theme.textMuted)
            Text("No recordings yet")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
            Text("Record from the Mic tab, then Save.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(app.theme.textMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ r: SavedRecording) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(r.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(app.theme.text)
                Text(relativeDate(r.createdAt))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
            }
            Spacer()
            Image(systemName: "play.circle")
                .font(.system(size: 18))
                .foregroundStyle(app.theme.accent)
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

private struct URLWrapper: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
