//
//  FontOption.swift
//  Sudoku
//

import SwiftUI

enum FontOption: String, CaseIterable {
    case standard = "Standard"
    case hand     = "Hand"
    
    var displayName: String {
        switch self {
        case .standard: String(localized: "Standard")
        case .hand:     String(localized: "Hand")
        }
    }
    
    func font(size: CGFloat) -> Font {
        switch self {
        case .standard: .system(size: size)
        case .hand:     .custom("Bradley Hand", size: size)
        }
    }
    
    func font(for style: Font.TextStyle) -> Font {
        guard case .hand = self else { return .system(style) }
        let size: CGFloat = switch style {
        case .largeTitle:             34
        case .title:                  28
        case .title2:                 22
        case .title3:                 20
        case .headline:               17
        case .subheadline:            15
        case .body:                   17
        case .callout:                16
        case .footnote:               13
        case .caption, .caption2:     12
        @unknown default:             17
        }
        return .custom("Bradley Hand", size: size, relativeTo: style)
    }
}

private struct FontOptionKey: EnvironmentKey {
    static let defaultValue = FontOption.standard
}

extension EnvironmentValues {
    var customFontOption: FontOption {
        get { self[FontOptionKey.self] }
        set { self[FontOptionKey.self] = newValue }
    }
}
