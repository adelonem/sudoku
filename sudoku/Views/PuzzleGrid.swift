//
//  PuzzleGrid.swift
//  sudoku
//

import SwiftUI

struct PuzzleGrid: View {
    @Environment(Game.self) private var game
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<Puzzle.size, id: \.self) { row in
                GridRow {
                    ForEach(0..<Puzzle.size, id: \.self) { col in
                        Rectangle()
                            .fill(color(for: highlight(row: row, col: col)))
                            .aspectRatio(1.0, contentMode: .fit)
                            .border(.gray.opacity(0.6), width: Style.gridCellBorderWidth)
                            .overlay {
                                let cellNotes = game.notes(atRow: row, col: col)
                                if let digit = game.digit(atRow: row, col: col) {
                                    Text("\(digit)")
                                        .font(.system(size: Style.digitFontSize))
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
                                        highlightedDigit: game.highlightedDigit
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
    
    // MARK: - Highlight logic
    
    private func highlight(row: Int, col: Int) -> CellHighlight {
        CellHighlight.forCell(
            atRow: row,
            col: col,
            selectedCell: game.selectedCell,
            highlightedDigit: game.highlightedDigit,
            digit: game.digit(atRow: row, col: col),
            hasConflict: game.hasConflict(atRow: row, col: col)
        )
    }
    
    private func color(for highlight: CellHighlight) -> Color {
        switch highlight {
        case .conflict:   .red.opacity(Style.conflictOpacity)
        case .digitMatch: Color.accentColor.opacity(Style.highlightOpacity)
        case .selected:   Color.accentColor.opacity(Style.highlightOpacity)
        case .peer:       Color.accentColor.opacity(Style.peerHighlightOpacity)
        case .none:       Style.background
        }
    }
}
