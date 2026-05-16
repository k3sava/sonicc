import SwiftUI
import UIKit

/// Hardware-keyboard shortcuts — useful when an iPad is paired with a
/// Magic Keyboard or a stage-manager iPhone is keyboard-attached. Mirrors
/// the keyboard mapping in index.html so users can keep muscle memory.
struct KeyboardShortcutLayer: ViewModifier {
    @EnvironmentObject var app: AppState

    func body(content: Content) -> some View {
        content
            .background {
                // Mode shortcuts. .keyboardShortcut needs a button as a target;
                // we hide invisible buttons in the background.
                Group {
                    Button("Keys") { app.mode = .keys }
                        .keyboardShortcut("1", modifiers: .command)
                    Button("Drums") { app.mode = .drums }
                        .keyboardShortcut("2", modifiers: .command)
                    Button("Pattern") { app.mode = .pattern }
                        .keyboardShortcut("3", modifiers: .command)
                    Button("Sampler") { app.mode = .sampler }
                        .keyboardShortcut("4", modifiers: .command)
                    Button("Mic") { app.mode = .mic }
                        .keyboardShortcut("5", modifiers: .command)
                    Button("Toggle play") {
                        if app.sequencer.isPlaying { app.sequencer.stop() } else { app.sequencer.play() }
                    }
                    .keyboardShortcut(" ", modifiers: [])
                    Button("Toggle record") { app.sequencer.toggleRecord() }
                        .keyboardShortcut("r", modifiers: [])
                    Button("Octave up") { app.baseOctave = min(7, app.baseOctave + 1) }
                        .keyboardShortcut(.upArrow, modifiers: [])
                    Button("Octave down") { app.baseOctave = max(0, app.baseOctave - 1) }
                        .keyboardShortcut(.downArrow, modifiers: [])
                }
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            }
    }
}

extension View {
    func keyboardShortcutLayer() -> some View {
        modifier(KeyboardShortcutLayer())
    }
}

/// Haptic feedback — sharp click for drum pads and keys.
enum Haptics {
    @MainActor static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    @MainActor static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
