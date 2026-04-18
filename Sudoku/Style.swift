//
//  Style.swift
//  Sudoku
//

import SwiftUI

/// Centralised design constants used across views.
enum Style {
    static let keyFontSize: CGFloat = 32
    static let noteFontSize: CGFloat = 16
    static let remainingCountFontSize: CGFloat = 14
    
    static let highlightOpacity: Double = 0.3
    static let peerHighlightOpacity: Double = 0.1
    static let disabledOpacity: Double = 0.4
    static let inactiveBackgroundOpacity: Double = 0.15
    
    /// The platform-appropriate opaque background color.
    static let background: Color = {
#if os(macOS)
        Color(nsColor: .textBackgroundColor)
#else
        Color(.systemBackground)
#endif
    }()
    
    /// Predefined accent colors the player can choose from.
    static let accentColors: [(name: String, color: Color)] = [
        ("Blue",   Color(red: 0.0,  green: 0.48, blue: 1.0)),
        ("Purple", Color(red: 0.57, green: 0.36, blue: 0.85)),
        ("Pink",   Color(red: 0.91, green: 0.30, blue: 0.53)),
        ("Red",    Color(red: 0.86, green: 0.24, blue: 0.24)),
        ("Orange", Color(red: 0.93, green: 0.55, blue: 0.15)),
        ("Green",  Color(red: 0.20, green: 0.72, blue: 0.40)),
        ("Teal",   Color(red: 0.19, green: 0.69, blue: 0.72)),
        ("Indigo", Color(red: 0.35, green: 0.34, blue: 0.84)),
    ]
}

private struct AccentColorKey: EnvironmentKey {
    static let defaultValue: Color = Style.accentColors[0].color
}

extension EnvironmentValues {
    var customAccentColor: Color {
        get { self[AccentColorKey.self] }
        set { self[AccentColorKey.self] = newValue }
    }
}
