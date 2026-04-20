//
//  CellView.swift
//  Sudoku
//

import SwiftUI

/// Displays the full content of a single grid cell: a digit (fixed or guess) or notes.
struct CellView: View {
    let cell: Cell
    let highlightedDigit: Int?
    var invalidNotes: Set<Int> = []
    var hasConflict: Bool = false
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        if let digit = cell.value {
            Text("\(digit)")
                .font(fontOption.font(size: Style.keyFontSize))
                .fontWeight(cell.isFixed ? .medium : .regular)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .foregroundStyle(cell.isFixed ? Color.primary : accentColor)
                .padding(2)
                .overlay {
                    if hasConflict && cell.isGuess {
                        AnimatedCrossOverlay()
                            .padding(6)
                    }
                }
        } else if !cell.notes.isEmpty {
            NotesView(
                notes: cell.notes,
                highlightedDigit: highlightedDigit,
                invalidNotes: invalidNotes
            )
            .padding(1)
        }
    }
}
