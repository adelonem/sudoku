//
//  PuzzleGrid.swift
//  sudoku
//

import SwiftUI

struct PuzzleGrid: View {
    let game: Game
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<Puzzle.size, id: \.self) { row in
                GridRow {
                    ForEach(0..<Puzzle.size, id: \.self) { col in
                        Rectangle()
                            .fill(cellColor(row: row, col: col))
                            .aspectRatio(1.0, contentMode: .fit)
                            .border(.gray.opacity(0.6), width: 0.5)
                            .overlay {
                                let cellNotes = game.notes(atRow: row, col: col)
                                if let digit = game.digit(atRow: row, col: col) {
                                    Text("\(digit)")
                                        .font(.system(size: 36))
                                        .fontWeight(.medium)
                                        .minimumScaleFactor(0.1)
                                        .lineLimit(1)
                                        .foregroundStyle(
                                            game.isClue(atRow: row, col: col)
                                            ? Color.primary
                                            : Color.accentColor
                                        )
                                        .padding(2)
                                } else if !cellNotes.isEmpty {
                                    PuzzleGridCell(
                                        notes: cellNotes,
                                        highlightedDigit: selectedDigit
                                    )
                                    .padding(1)
                                }
                            }
                            .onTapGesture {
                                game.select(row: row, col: col)
                            }
                    }
                }
            }
        }
        .overlay {
            BlockGridOverlay()
                .allowsHitTesting(false)
        }
    }
    
    /// The digit to highlight across the grid, driven by the last user action.
    private var selectedDigit: Int? {
        game.highlightedDigit
    }
    
    private static let defaultCellColor: Color = .platformBackground
    
    private func cellColor(row: Int, col: Int) -> Color {
        if game.hasConflict(atRow: row, col: col) {
            return .red.opacity(0.15)
        }
        
        // Highlight cells whose digit matches the active highlighted digit
        if let selectedDigit, let digit = game.digit(atRow: row, col: col), selectedDigit == digit {
            return Color.accentColor.opacity(0.3)
        }
        
        guard let selected = game.selectedCell else { return Self.defaultCellColor }
        
        // Highlight the selected cell
        if selected.row == row && selected.col == col {
            return Color.accentColor.opacity(0.3)
        }
        
        // Highlight cells in the same row, column, or 3×3 block
        let bs = Puzzle.blockSize
        if selected.row == row
            || selected.col == col
            || (selected.row / bs == row / bs && selected.col / bs == col / bs) {
            return Color.accentColor.opacity(0.1)
        }
        
        return Self.defaultCellColor
    }
}

extension Color {
    /// The platform-appropriate opaque background color.
    static let platformBackground: Color = {
#if os(macOS)
        Color(nsColor: .textBackgroundColor)
#else
        Color(.systemBackground)
#endif
    }()
}
