import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var intents = IntentMailbox.shared
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if isPad {
                IPadRootView()
            } else {
                IPhoneRootView()
            }
        }
        .tint(app.theme.accent)
        .background(app.theme.bg.ignoresSafeArea())
        .keyboardShortcutLayer()
        // Hard paywall — trial expired, must buy or restore to continue.
        .fullScreenCover(isPresented: .constant(app.trial.isLocked && !app.trial.isUnlocked)) {
            PaywallView(gate: app.trial, store: app.iap, allowDismiss: false)
                .environmentObject(app)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                app.trial.recompute()
                Task { await app.iap.refreshEntitlements() }
            }
        }
        .onChange(of: intents.pendingMode) { _, v in
            guard let v, let m = AppState.Mode(rawValue: v) else { return }
            app.mode = m
            intents.pendingMode = nil
        }
        .onChange(of: intents.pendingPlay) { _, v in
            if v { app.sequencer.play(); intents.pendingPlay = false }
        }
        .onChange(of: intents.pendingStop) { _, v in
            if v { app.sequencer.stop(); intents.pendingStop = false }
        }
        .onChange(of: intents.pendingRecord) { _, v in
            if v { app.sequencer.toggleRecord(); intents.pendingRecord = false }
        }
    }

    private var isPad: Bool {
        // iPad in any orientation has regular hSize. Treat regular+regular as
        // the iPad layout; everything else uses the phone shell.
        hSize == .regular && vSize == .regular
    }
}
