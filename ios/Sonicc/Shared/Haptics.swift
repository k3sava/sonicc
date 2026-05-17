import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Single source of truth for haptic feedback. Respects Reduce Motion
/// (which often signals reduced haptics too). Use these helpers instead
/// of spawning generators inline so we can audit + tune in one place.
enum Haptics {
    static var enabled: Bool = true

    static func tap(_ style: ImpactStyle = .light) {
        #if canImport(UIKit)
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style.uiStyle)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }

    static func select() {
        #if canImport(UIKit)
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    static func notify(_ type: NotificationType) {
        #if canImport(UIKit)
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type.uiType)
        #endif
    }

    enum ImpactStyle {
        case light, medium, heavy, rigid, soft
        #if canImport(UIKit)
        var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:  return .light
            case .medium: return .medium
            case .heavy:  return .heavy
            case .rigid:  return .rigid
            case .soft:   return .soft
            }
        }
        #endif
    }

    enum NotificationType {
        case success, warning, error
        #if canImport(UIKit)
        var uiType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error:   return .error
            }
        }
        #endif
    }
}
