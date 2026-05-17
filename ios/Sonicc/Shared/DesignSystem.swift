import SwiftUI

/// Apple-grade design tokens. Typography that respects Dynamic Type,
/// spacing on an 8pt rhythm, semantic colors layered over the user's
/// chosen AppTheme, motion tokens that respect Reduce Motion.
///
/// Use these instead of raw `.font(.system(size: 11))` calls so the UI
/// scales with the user's accessibility preferences and stays consistent.
enum DS {

    // MARK: - Spacing (8pt rhythm)

    enum Space {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Touch targets

    /// Apple HIG minimum touch target. Every interactive control hits this.
    static let minTarget: CGFloat = 44

    // MARK: - Typography

    /// Scales with Dynamic Type. The `size` is the size at the user's
    /// default text size; iOS scales it from there.
    static func font(_ style: TextStyle, weight: Font.Weight = .regular,
                     monospaced: Bool = false) -> Font {
        let design: Font.Design = monospaced ? .monospaced : .default
        return .system(style.textStyle, design: design).weight(weight)
    }

    enum TextStyle {
        case display       // .largeTitle  — chord readout, hero number
        case title         // .title2      — section title
        case body          // .body        — primary readable text
        case label         // .subheadline — UI control label
        case caption       // .caption     — helper / unit / metadata
        case micro         // .caption2    — last-resort tiny

        var textStyle: Font.TextStyle {
            switch self {
            case .display: return .largeTitle
            case .title:   return .title2
            case .body:    return .body
            case .label:   return .subheadline
            case .caption: return .caption
            case .micro:   return .caption2
            }
        }
    }

    // MARK: - Radii

    enum Radius {
        static let chip: CGFloat = 10
        static let card: CGFloat = 14
        static let sheet: CGFloat = 22
    }

    // MARK: - Motion

    /// Spring that respects Reduce Motion. When the user has Reduce Motion
    /// on, returns a near-instant transition.
    static func spring(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.001)
                     : .spring(response: 0.32, dampingFraction: 0.78)
    }

    static func ease(reduceMotion: Bool, duration: Double = 0.18) -> Animation {
        reduceMotion ? .linear(duration: 0.001)
                     : .easeInOut(duration: duration)
    }
}

// MARK: - Semantic palette (layered over AppTheme)

/// Apple HIG-style semantic colors. Each derives from the active AppTheme
/// but carries a clear role: `interactive` for tappable surfaces, `glass`
/// for elevated layers, `warning` for destructive, etc.
struct Semantic {
    let theme: AppTheme

    // Foundation
    var canvas:       Color { theme.bg }
    var surface:      Color { theme.surface }
    var elevated:     Color { theme.surface }
    var hairline:     Color { theme.border.opacity(0.6) }
    var divider:      Color { theme.border.opacity(0.4) }

    // Text — guaranteed-contrast roles
    var ink:          Color { theme.text }
    var inkSoft:      Color { theme.text.opacity(0.72) }
    var inkMuted:     Color { theme.text.opacity(0.52) }

    // Interaction
    var accent:       Color { theme.accent }
    var accentSoft:   Color { theme.accent.opacity(0.14) }
    var accentGlow:   Color { theme.accent.opacity(0.28) }

    // Semantic states
    var success:      Color { Color(hue: 0.35, saturation: 0.7, brightness: 0.6) }
    var warning:      Color { Color(hue: 0.08, saturation: 0.85, brightness: 0.85) }
    var destructive:  Color { Color(red: 0.85, green: 0.23, blue: 0.21) }

    // Piano-specific
    var keyWhite:     Color { theme.surface }
    var keyBlack:     Color { theme.text }
    var keyShadow:    Color { theme.text.opacity(0.10) }
    var keyHighlight: Color { theme.accent.opacity(0.32) }
    var keyAnchor:    Color { theme.accent.opacity(0.45) }      // middle C tint
    var keyInScale:   Color { theme.accent.opacity(0.08) }      // scale-tinted notes

    // Pattern grid
    var cellOff:      Color { theme.surface }
    var cellActive:   Color { theme.accent.opacity(0.18) }      // current step
    var cellOn:       Color { theme.accent }
}

extension AppTheme {
    var semantic: Semantic { Semantic(theme: self) }
}

// MARK: - View helpers

extension View {
    /// Ensures the view hits at least Apple's 44pt minimum touch target
    /// while leaving the visual content at its natural size.
    func minTouchTarget(_ size: CGFloat = DS.minTarget) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }

    /// One-line accessibility helper.
    func a11y(_ label: String, value: String? = nil, hint: String? = nil) -> some View {
        let value = value
        let hint = hint
        return self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
    }
}
