//
//  Style.swift
//  sudoku
//

import SwiftUI

/// Centralised design constants used across views.
enum Style {
    // MARK: - Font sizes
    static let digitFontSize: CGFloat = 36
    static let noteFontSize: CGFloat = 18
    static let remainingCountFontSize: CGFloat = 18
    
    // MARK: - Opacities
    static let highlightOpacity: Double = 0.3
    static let peerHighlightOpacity: Double = 0.1
    static let conflictOpacity: Double = 0.15
    static let disabledOpacity: Double = 0.4
    static let inactiveBackgroundOpacity: Double = 0.15
    static let overlayDimOpacity: Double = 0.4
    
    // MARK: - Corner radii
    static let keyCornerRadius: CGFloat = 8
    static let progressIndicatorCornerRadius: CGFloat = 8
    static let victoryCornerRadius: CGFloat = 20
    
    // MARK: - Spacing
    static let gridCellBorderWidth: CGFloat = 0.5
    static let blockBorderWidth: CGFloat = 2
    
    // MARK: - Colors
    
    /// The platform-appropriate opaque background color.
    static let background: Color = {
#if os(macOS)
        Color(nsColor: .textBackgroundColor)
#else
        Color(.systemBackground)
#endif
    }()
}
