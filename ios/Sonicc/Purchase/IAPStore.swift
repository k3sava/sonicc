import Foundation
import StoreKit

/// Thin async/await wrapper around StoreKit 2 for a single non-consumable
/// in-app purchase (lifetime unlock). Owns the product lookup, the buy
/// flow, the restore flow, and a long-lived transaction listener.
///
/// The wider app talks to this via `TrialGate` — IAPStore just calls
/// `gate.markPurchased()` when it sees ownership.
@MainActor
final class IAPStore: ObservableObject {

    @Published private(set) var product: Product?
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var lastError: String?

    private let gate: TrialGate
    private var listener: Task<Void, Never>?

    init(gate: TrialGate) {
        self.gate = gate
        listener = Task.detached { [weak self] in
            await self?.observeTransactions()
        }
    }

    deinit { listener?.cancel() }

    /// Fetch the product metadata. Call from app launch + when the paywall
    /// is presented in case the first fetch failed (offline at launch).
    func refresh() async {
        do {
            let products = try await Product.products(for: [gate.productID])
            self.product = products.first
            await refreshEntitlements()
        } catch {
            self.lastError = "Couldn't reach the App Store."
        }
    }

    /// Re-check current entitlements (used after launch + after restore).
    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == gate.productID, t.revocationDate == nil {
                gate.markPurchased()
                return
            }
        }
    }

    /// Initiate the buy flow for the configured product.
    func buy() async {
        guard let product else {
            lastError = "Product not loaded yet."
            await refresh()
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    gate.markPurchased()
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                lastError = "Purchase pending approval."
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed. Please try again."
        }
    }

    /// Restore purchases — required by App Store guidelines for non-
    /// consumables. Asks StoreKit to sync entitlements with Apple ID.
    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !gate.isUnlocked {
                lastError = "No previous purchase found on this Apple ID."
            }
        } catch {
            lastError = "Couldn't reach the App Store."
        }
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let t) = result, t.productID == gate.productID, t.revocationDate == nil {
                await MainActor.run { gate.markPurchased() }
                await t.finish()
            }
        }
    }
}
