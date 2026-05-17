import Foundation
import SwiftUI

/// On-disk archive of saved step patterns. Lives under Application Support so
/// patterns survive app deletes via iCloud backup but don't end up in iCloud
/// Drive. JSON-encoded for forward-compat and easy export.
@MainActor
final class PatternLibrary: ObservableObject {

    static let shared = PatternLibrary()

    @Published private(set) var patterns: [SavedPattern] = []

    private let folder: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let f = base.appendingPathComponent("sonicc-patterns", isDirectory: true)
        try? FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        return f
    }()

    init() { refresh() }

    // MARK: - File ops

    func save(_ pattern: SavedPattern) {
        let url = folder.appendingPathComponent("\(pattern.id.uuidString).json")
        do {
            let data = try JSONEncoder().encode(pattern)
            try data.write(to: url, options: .atomic)
            refresh()
        } catch {
            print("PatternLibrary save error: \(error)")
        }
    }

    func delete(_ pattern: SavedPattern) {
        let url = folder.appendingPathComponent("\(pattern.id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
        refresh()
    }

    func rename(_ pattern: SavedPattern, to newName: String) {
        var copy = pattern
        copy.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.updatedAt = Date()
        save(copy)
    }

    func refresh() {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        var built: [SavedPattern] = []
        for url in urls where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let p = try? JSONDecoder().decode(SavedPattern.self, from: data) else { continue }
            built.append(p)
        }
        patterns = built.sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Codable snapshot

struct SavedPattern: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var bpm: Double
    var swing: Double
    var stepCount: Int
    var synthCells: [[Bool]]
    var drumCells: [[Bool]]
    var synthNotes: [Int: NotePitchSnapshot]
    var presetID: String?
    var themeID: String?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        bpm: Double,
        swing: Double,
        stepCount: Int,
        synthCells: [[Bool]],
        drumCells: [[Bool]],
        synthNotes: [Int: NotePitchSnapshot],
        presetID: String? = nil,
        themeID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bpm = bpm
        self.swing = swing
        self.stepCount = stepCount
        self.synthCells = synthCells
        self.drumCells = drumCells
        self.synthNotes = synthNotes
        self.presetID = presetID
        self.themeID = themeID
    }
}

struct NotePitchSnapshot: Codable, Equatable {
    let note: Int
    let octave: Int
}
