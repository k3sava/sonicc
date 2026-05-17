import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
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
    }

    private var isPad: Bool {
        // iPad in any orientation has regular hSize. Treat regular+regular as
        // the iPad layout; everything else uses the phone shell.
        hSize == .regular && vSize == .regular
    }
}
