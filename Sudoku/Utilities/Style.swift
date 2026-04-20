//
//  Style.swift
//  Sudoku
//

import SwiftUI

/// Centralised design constants used across views.
enum Style {
    struct AccentColorOption {
        let name: String
        let color: Color
        
        var localizedName: String {
            switch name {
            case "Blue":   String(localized: "Blue")
            case "Purple": String(localized: "Purple")
            case "Pink":   String(localized: "Pink")
            case "Red":    String(localized: "Red")
            case "Orange": String(localized: "Orange")
            case "Green":  String(localized: "Green")
            case "Teal":   String(localized: "Teal")
            case "Indigo": String(localized: "Indigo")
            default:       name
            }
        }
    }
    
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
    static let accentColors: [AccentColorOption] = [
        AccentColorOption(name: "Blue", color: Color(red: 0.0,  green: 0.48, blue: 1.0)),
        AccentColorOption(name: "Purple", color: Color(red: 0.57, green: 0.36, blue: 0.85)),
        AccentColorOption(name: "Pink", color: Color(red: 0.91, green: 0.30, blue: 0.53)),
        AccentColorOption(name: "Red", color: Color(red: 0.86, green: 0.24, blue: 0.24)),
        AccentColorOption(name: "Orange", color: Color(red: 0.93, green: 0.55, blue: 0.15)),
        AccentColorOption(name: "Green", color: Color(red: 0.20, green: 0.72, blue: 0.40)),
        AccentColorOption(name: "Teal", color: Color(red: 0.19, green: 0.69, blue: 0.72)),
        AccentColorOption(name: "Indigo", color: Color(red: 0.35, green: 0.34, blue: 0.84)),
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
