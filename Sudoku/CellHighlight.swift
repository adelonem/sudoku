//
//  CellHighlight.swift
//  Sudoku
//

import SwiftUI

/// Describes the visual highlight state of a grid cell.
enum CellHighlight {
    case conflict
    case digitMatch
    case selected
    case peer
    /// Cell directly targeted by a hint technique (strong amber, theme-independent).
    case hintPrimary
    /// Context cell justifying a hint (light amber, theme-independent).
    case hintSecondary
    case none
    
    private static let hintColor: Color = .orange
    
    func color(accent: Color) -> Color {
        switch self {
        case .conflict:      Style.background
        case .digitMatch:    accent.opacity(Style.highlightOpacity)
        case .selected:      accent.opacity(Style.highlightOpacity)
        case .peer:          accent.opacity(Style.peerHighlightOpacity)
        case .hintPrimary:   Self.hintColor.opacity(Style.highlightOpacity)
        case .hintSecondary: Self.hintColor.opacity(Style.peerHighlightOpacity)
        case .none:          Style.background
        }
    }
}
