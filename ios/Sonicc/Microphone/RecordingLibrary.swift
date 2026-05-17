import Foundation
import SwiftUI

/// On-disk archive of saved mic recordings (.caf). Lives under
/// Application Support / sonicc-recordings.
@MainActor
final class RecordingLibrary: ObservableObject {

    static let shared = RecordingLibrary()

    @Published private(set) var recordings: [SavedRecording] = []

    private let folder: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let f = base.appendingPathComponent("sonicc-recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        return f
    }()

    init() { refresh() }

    /// Move a freshly-written recording into the library, naming it.
    @discardableResult
    func adopt(from sourceURL: URL, name: String) -> SavedRecording? {
        let safe = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = safe.isEmpty ? "Recording \(recordings.count + 1)" : safe
        let id = UUID()
        let target = folder.appendingPathComponent("\(id.uuidString).caf")
        do {
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.moveItem(at: sourceURL, to: target)
        } catch {
            print("RecordingLibrary adopt error: \(error)")
            return nil
        }
        let rec = SavedRecording(id: id, name: finalName, url: target, createdAt: .now)
        writeMetadata(rec)
        refresh()
        return rec
    }

    func delete(_ rec: SavedRecording) {
        try? FileManager.default.removeItem(at: rec.url)
        let meta = folder.appendingPathComponent("\(rec.id.uuidString).json")
        try? FileManager.default.removeItem(at: meta)
        refresh()
    }

    func refresh() {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey])) ?? []
        var built: [SavedRecording] = []
        for url in urls where url.pathExtension == "caf" {
            let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) ?? UUID()
            let metaURL = folder.appendingPathComponent("\(id.uuidString).json")
            var name = url.lastPathComponent
            var createdAt = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .now
            if let data = try? Data(contentsOf: metaURL),
               let meta = try? JSONDecoder().decode(RecordingMetadata.self, from: data) {
                name = meta.name
                createdAt = meta.createdAt
            }
            built.append(SavedRecording(id: id, name: name, url: url, createdAt: createdAt))
        }
        recordings = built.sorted { $0.createdAt > $1.createdAt }
    }

    private func writeMetadata(_ rec: SavedRecording) {
        let meta = RecordingMetadata(name: rec.name, createdAt: rec.createdAt)
        let metaURL = folder.appendingPathComponent("\(rec.id.uuidString).json")
        if let data = try? JSONEncoder().encode(meta) {
            try? data.write(to: metaURL, options: .atomic)
        }
    }
}

struct SavedRecording: Identifiable, Equatable {
    let id: UUID
    let name: String
    let url: URL
    let createdAt: Date
}

private struct RecordingMetadata: Codable {
    let name: String
    let createdAt: Date
}
