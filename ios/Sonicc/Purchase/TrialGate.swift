import Foundation
import SwiftUI

/// Tracks the user's trial state. Records the install date on first launch,
/// computes how many days are left, and exposes a single `state` enum the
/// UI binds to so the rest of the app doesn't need to know about dates.
///
/// Trial period is fixed at `trialDays` (default 7). After it expires and
/// the user hasn't purchased the unlock, `state == .expired` and the
/// paywall is presented.
final class TrialGate: ObservableObject {

    enum State: Equatable {
        case trial(daysRemaining: Int)
        case expired
        case purchased
    }

    @Published private(set) var state: State = .trial(daysRemaining: 7)

    let trialDays: Int
    private let installDateKey = "kami.trial.installDate"
    private let purchasedKey = "kami.trial.purchased"

    /// Lifetime IAP product identifier. Set per-app.
    let productID: String

    init(productID: String, trialDays: Int = 7) {
        self.productID = productID
        self.trialDays = trialDays
        ensureInstallDateRecorded()
        recompute()
    }

    /// Recompute trial state from persisted install date + purchase flag.
    /// Safe to call from any thread; publishes on main.
    func recompute() {
        let next: State
        if UserDefaults.standard.bool(forKey: purchasedKey) {
            next = .purchased
        } else {
            let elapsed = Date().timeIntervalSince(installDate())
            let trialSeconds = TimeInterval(trialDays) * 86_400
            let remaining = trialSeconds - elapsed
            if remaining <= 0 {
                next = .expired
            } else {
                let days = max(1, Int(ceil(remaining / 86_400)))
                next = .trial(daysRemaining: days)
            }
        }
        publish(next)
    }

    /// Mark the unlock as owned. Called by IAPStore when a purchase or
    /// restore completes successfully.
    func markPurchased() {
        UserDefaults.standard.set(true, forKey: purchasedKey)
        publish(.purchased)
    }

    private func publish(_ next: State) {
        if Thread.isMainThread {
            self.state = next
        } else {
            DispatchQueue.main.async { self.state = next }
        }
    }

    /// Wipe the purchase flag — used by debug menu / TestFlight reset.
    func reset() {
        UserDefaults.standard.removeObject(forKey: purchasedKey)
        UserDefaults.standard.removeObject(forKey: installDateKey)
        ensureInstallDateRecorded()
        recompute()
    }

    var isLocked: Bool {
        if case .expired = state { return true }
        return false
    }

    var isUnlocked: Bool {
        if case .purchased = state { return true }
        return false
    }

    // MARK: - Private

    private func ensureInstallDateRecorded() {
        if UserDefaults.standard.object(forKey: installDateKey) == nil {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: installDateKey)
        }
    }

    private func installDate() -> Date {
        let t = UserDefaults.standard.double(forKey: installDateKey)
        return Date(timeIntervalSince1970: t)
    }
}
