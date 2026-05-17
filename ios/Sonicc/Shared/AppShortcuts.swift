import AppIntents
import SwiftUI

// MARK: - Mode launcher (URL-scheme-free deep linking via env actions)

/// Tiny mailbox the AppIntent posts to. The app's root reads it on
/// appear/onChange and dispatches the action. Keeps intents totally
/// decoupled from AppState (which lives in @MainActor land).
@MainActor
final class IntentMailbox: ObservableObject {
    static let shared = IntentMailbox()
    @Published var pendingMode: String?
    @Published var pendingPlay: Bool = false
    @Published var pendingStop: Bool = false
    @Published var pendingRecord: Bool = false
}

// MARK: - Intents

/// Open Sonicc directly to one of its surfaces.
struct OpenModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Mode"
    static let description = IntentDescription("Open Sonicc to a specific surface — Keys, Drums, Pattern, Sampler, or Mic.")
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Mode")
    var mode: ModeChoice

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentMailbox.shared.pendingMode = mode.rawValue
        }
        return .result()
    }
}

enum ModeChoice: String, AppEnum {
    case keys, drums, pattern, sampler, mic

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Mode" }
    static var caseDisplayRepresentations: [ModeChoice: DisplayRepresentation] = [
        .keys:    "Keys",
        .drums:   "Drums",
        .pattern: "Pattern",
        .sampler: "Sampler",
        .mic:     "Mic",
    ]
}

/// Start the sequencer playing.
struct PlaySequencerIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Sequencer"
    static let description = IntentDescription("Start the Sonicc step sequencer playing.")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run { IntentMailbox.shared.pendingPlay = true }
        return .result()
    }
}

struct StopSequencerIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Sequencer"
    static let description = IntentDescription("Stop the Sonicc step sequencer.")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run { IntentMailbox.shared.pendingStop = true }
        return .result()
    }
}

struct ArmRecordIntent: AppIntent {
    static let title: LocalizedStringResource = "Arm Record"
    static let description = IntentDescription("Toggle record-arm on the Sonicc sequencer.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { IntentMailbox.shared.pendingRecord = true }
        return .result()
    }
}

// MARK: - Provider — registers shortcuts so they show up in Spotlight + Siri

struct SoniccShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlaySequencerIntent(),
            phrases: [
                "Play \(.applicationName)",
                "Start \(.applicationName)",
            ],
            shortTitle: "Play",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StopSequencerIntent(),
            phrases: [
                "Stop \(.applicationName)",
            ],
            shortTitle: "Stop",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: ArmRecordIntent(),
            phrases: [
                "Record in \(.applicationName)",
                "Arm record in \(.applicationName)",
            ],
            shortTitle: "Record",
            systemImageName: "record.circle"
        )
        AppShortcut(
            intent: OpenModeIntent(),
            phrases: [
                "Open keys in \(.applicationName)",
                "Open drums in \(.applicationName)",
                "Open pattern in \(.applicationName)",
                "Open sampler in \(.applicationName)",
                "Open mic in \(.applicationName)",
            ],
            shortTitle: "Open Mode",
            systemImageName: "music.note.list"
        )
    }
}
