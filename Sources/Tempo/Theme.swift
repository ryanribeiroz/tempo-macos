import AppKit
import SwiftUI

extension Color {
    static let tempoCanvas = adaptive(
        light: NSColor(red: 0.945, green: 0.965, blue: 0.98, alpha: 1),
        dark: NSColor(red: 0.063, green: 0.09, blue: 0.133, alpha: 1)
    )
    static let tempoStage = adaptive(
        light: NSColor(red: 0.85, green: 0.89, blue: 0.92, alpha: 1),
        dark: NSColor(red: 0.094, green: 0.141, blue: 0.20, alpha: 1)
    )
    static let tempoInk = adaptive(
        light: NSColor(red: 0.09, green: 0.13, blue: 0.18, alpha: 1),
        dark: NSColor(red: 0.929, green: 0.957, blue: 0.98, alpha: 1)
    )
    static let tempoMuted = adaptive(
        light: NSColor(red: 0.34, green: 0.39, blue: 0.44, alpha: 1),
        dark: NSColor(red: 0.62, green: 0.678, blue: 0.737, alpha: 1)
    )
    static let tempoMain = adaptive(
        light: NSColor(red: 0.13, green: 0.39, blue: 0.78, alpha: 1),
        dark: NSColor(red: 0.357, green: 0.569, blue: 0.925, alpha: 1)
    )
    static let tempoExternal = adaptive(
        light: NSColor(red: 0.22, green: 0.56, blue: 0.69, alpha: 1),
        dark: NSColor(red: 0.298, green: 0.655, blue: 0.761, alpha: 1)
    )
    static let tempoRecord = adaptive(
        light: NSColor(red: 0.90, green: 0.23, blue: 0.22, alpha: 1),
        dark: NSColor(red: 1, green: 0.384, blue: 0.369, alpha: 1)
    )
    static let tempoPause = adaptive(
        light: NSColor(red: 0.86, green: 0.49, blue: 0.10, alpha: 1),
        dark: NSColor(red: 0.949, green: 0.639, blue: 0.227, alpha: 1)
    )
    static let tempoBorder = adaptive(
        light: NSColor(white: 1, alpha: 0.72),
        dark: NSColor(red: 0.31, green: 0.39, blue: 0.48, alpha: 0.72)
    )
    static let tempoShadow = adaptive(
        light: NSColor(red: 0.09, green: 0.13, blue: 0.18, alpha: 0.08),
        dark: NSColor(white: 0, alpha: 0.34)
    )

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}
