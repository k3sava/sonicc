import Foundation
import SwiftUI

struct AppTheme: Identifiable, Equatable {
    let id: String
    let displayName: String
    let bg: Color
    let surface: Color
    let border: Color
    let text: Color
    let textMuted: Color
    let accent: Color
    let accentSoft: Color
    let canvasBG: Color
    let preferredColorScheme: ColorScheme?
    let fontUI: String?
    let fontLabel: String?
    let cornerRadius: CGFloat
    let buttonStyle: ButtonShape
    let motion: Double

    enum ButtonShape { case rounded, sharp, soft }
}

extension AppTheme {
    static let `default` = AppTheme(
        id: "default",
        displayName: "default",
        bg: Color(red: 0.965, green: 0.965, blue: 0.957),
        surface: .white,
        border: Color(white: 0.90),
        text: Color(red: 0.114, green: 0.114, blue: 0.122),
        textMuted: Color(red: 0.294, green: 0.345, blue: 0.388),
        accent: Color(red: 0.145, green: 0.388, blue: 0.922),
        accentSoft: Color(red: 0.145, green: 0.388, blue: 0.922).opacity(0.08),
        canvasBG: Color(red: 0.066, green: 0.066, blue: 0.066),
        preferredColorScheme: .light,
        fontUI: nil, fontLabel: nil,
        cornerRadius: 16,
        buttonStyle: .rounded,
        motion: 0.22
    )

    static let brutalist = AppTheme(
        id: "brutalist",
        displayName: "brutalist",
        bg: .white, surface: .white,
        border: .black,
        text: .black, textMuted: .gray,
        accent: .black, accentSoft: Color.black.opacity(0.08),
        canvasBG: .black,
        preferredColorScheme: .light,
        fontUI: "Menlo", fontLabel: "Menlo",
        cornerRadius: 0, buttonStyle: .sharp, motion: 0.04
    )

    static let editorial = AppTheme(
        id: "editorial",
        displayName: "editorial",
        bg: Color(red: 0.98, green: 0.96, blue: 0.91),
        surface: Color(red: 1.0, green: 0.99, blue: 0.96),
        border: Color(red: 0.83, green: 0.78, blue: 0.66),
        text: Color(red: 0.20, green: 0.15, blue: 0.10),
        textMuted: Color(red: 0.39, green: 0.32, blue: 0.24),
        accent: Color(red: 0.50, green: 0.20, blue: 0.16),
        accentSoft: Color(red: 0.50, green: 0.20, blue: 0.16).opacity(0.08),
        canvasBG: Color(red: 0.13, green: 0.10, blue: 0.07),
        preferredColorScheme: .light,
        fontUI: "Georgia", fontLabel: "Georgia",
        cornerRadius: 8, buttonStyle: .rounded, motion: 0.22
    )

    static let terminal = AppTheme(
        id: "terminal",
        displayName: "terminal",
        bg: Color(red: 0.02, green: 0.06, blue: 0.02),
        surface: Color(red: 0.04, green: 0.08, blue: 0.04),
        border: Color(red: 0.13, green: 0.32, blue: 0.13),
        text: Color(red: 0.36, green: 0.95, blue: 0.36),
        textMuted: Color(red: 0.22, green: 0.65, blue: 0.22),
        accent: Color(red: 0.36, green: 0.95, blue: 0.36),
        accentSoft: Color(red: 0.36, green: 0.95, blue: 0.36).opacity(0.12),
        canvasBG: .black,
        preferredColorScheme: .dark,
        fontUI: "Menlo", fontLabel: "Menlo",
        cornerRadius: 2, buttonStyle: .sharp, motion: 0.016
    )

    static let zen = AppTheme(
        id: "zen",
        displayName: "zen",
        bg: Color(red: 0.92, green: 0.93, blue: 0.94),
        surface: Color(red: 0.97, green: 0.97, blue: 0.97),
        border: Color(white: 0.85),
        text: Color(red: 0.14, green: 0.18, blue: 0.22),
        textMuted: Color(red: 0.38, green: 0.43, blue: 0.49),
        accent: Color(red: 0.39, green: 0.58, blue: 0.65),
        accentSoft: Color(red: 0.39, green: 0.58, blue: 0.65).opacity(0.10),
        canvasBG: Color(red: 0.09, green: 0.10, blue: 0.12),
        preferredColorScheme: .light,
        fontUI: "Avenir", fontLabel: "Avenir",
        cornerRadius: 20, buttonStyle: .soft, motion: 0.40
    )

    static let all: [AppTheme] = [.default, .brutalist, .editorial, .terminal, .zen]
    static let storageKey = "sonicc.theme.id"
}
