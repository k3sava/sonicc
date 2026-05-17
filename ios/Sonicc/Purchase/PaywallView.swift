import SwiftUI
import StoreKit

/// Apple-grade paywall. Used in two modes:
///   - Hard gate: when the trial has expired, the user must either buy or
///     restore. No way past until they do.
///   - Soft sheet: presented from Settings → Upgrade so users can buy
///     before the trial runs out if they want to support the maker.
struct PaywallView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var gate: TrialGate
    @ObservedObject var store: IAPStore
    @Environment(\.dismiss) private var dismiss
    var allowDismiss: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .center, spacing: DS.Space.lg) {
                    icon
                    headline
                    features
                    pricing
                    if let err = store.lastError {
                        Text(err)
                            .font(DS.font(.caption))
                            .foregroundStyle(app.theme.semantic.destructive)
                            .multilineTextAlignment(.center)
                    }
                    smallPrint
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, DS.Space.xl)
            }
            footer
        }
        .background(app.theme.semantic.canvas.ignoresSafeArea())
        .interactiveDismissDisabled(!allowDismiss)
        .task { if store.product == nil { await store.refresh() } }
    }

    // MARK: - Sections

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [app.theme.semantic.accent.opacity(0.9),
                                              app.theme.semantic.accent.opacity(0.6)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 96, height: 96)
                .shadow(color: app.theme.semantic.accent.opacity(0.35), radius: 18, y: 8)
            Image(systemName: "pianokeys")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.top, DS.Space.lg)
    }

    private var headline: some View {
        VStack(spacing: DS.Space.sm) {
            Text(gate.isLocked ? "Trial complete" : "Unlock sonicc")
                .font(.system(.title, design: .default).weight(.semibold))
                .foregroundStyle(app.theme.semantic.ink)
                .multilineTextAlignment(.center)
            Text(gate.isLocked
                 ? "Buy once to keep playing. No subscription."
                 : "Skip the countdown. One-time payment, yours forever.")
                .font(DS.font(.body))
                .foregroundStyle(app.theme.semantic.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            feature("pianokeys", "Velocity keys, scale picker, sustain pedal")
            feature("waveform.path.badge.plus", "Pattern chain, triplet subdivisions, WAV export")
            feature("mic.fill", "Mic recording with M4A and WAV bounces")
            feature("checkmark.shield.fill", "Yours on every device signed in to your Apple ID")
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card).fill(app.theme.semantic.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(app.theme.semantic.hairline))
    }

    private func feature(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(app.theme.semantic.accent)
                .frame(width: 26, height: 26, alignment: .top)
            Text(text)
                .font(DS.font(.body))
                .foregroundStyle(app.theme.semantic.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pricing: some View {
        VStack(spacing: 4) {
            if let product = store.product {
                Text(product.displayPrice)
                    .font(.system(.title2, design: .default).weight(.semibold))
                    .foregroundStyle(app.theme.semantic.ink)
                Text("One-time payment · no subscription")
                    .font(DS.font(.caption))
                    .foregroundStyle(app.theme.semantic.inkSoft)
            } else {
                ProgressView()
                Text("Loading price…")
                    .font(DS.font(.caption))
                    .foregroundStyle(app.theme.semantic.inkSoft)
            }
        }
        .padding(.top, DS.Space.sm)
    }

    private var smallPrint: some View {
        VStack(alignment: .center, spacing: 4) {
            switch gate.state {
            case .trial(let days):
                Text("Trial: \(days) day\(days == 1 ? "" : "s") left")
                    .font(DS.font(.caption, weight: .medium, monospaced: true))
                    .foregroundStyle(app.theme.semantic.accent)
            case .expired:
                Text("Your free trial has ended.")
                    .font(DS.font(.caption, weight: .medium, monospaced: true))
                    .foregroundStyle(app.theme.semantic.warning)
            case .purchased:
                Text("Unlocked — thank you for supporting kami studios.")
                    .font(DS.font(.caption, weight: .medium))
                    .foregroundStyle(app.theme.semantic.success)
            }
            Text("Purchases tied to your Apple ID. Family Sharing supported.")
                .font(DS.font(.micro))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .padding(.top, 2)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: DS.Space.sm) {
                Button {
                    Task { await store.buy() }
                    Haptics.tap(.medium)
                } label: {
                    if store.isPurchasing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    } else {
                        Text(buyButtonText)
                            .font(DS.font(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                }
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip).fill(app.theme.semantic.accent))
                .foregroundStyle(Color.white)
                .disabled(store.isPurchasing || store.product == nil)
                .a11y("Buy", value: store.product?.displayPrice ?? "loading")

                HStack {
                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .font(DS.font(.caption, weight: .medium))
                    .foregroundStyle(app.theme.semantic.accent)
                    .disabled(store.isPurchasing)
                    Spacer()
                    if allowDismiss {
                        Button("Maybe later") { dismiss() }
                            .font(DS.font(.caption, weight: .medium))
                            .foregroundStyle(app.theme.semantic.inkSoft)
                    }
                }
                .padding(.horizontal, DS.Space.xs)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.md)
        }
        .background(app.theme.semantic.surface)
    }

    private var buyButtonText: String {
        if let product = store.product {
            return "Unlock for \(product.displayPrice)"
        }
        return "Unlock"
    }
}
