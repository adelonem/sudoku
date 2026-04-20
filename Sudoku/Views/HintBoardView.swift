//
//  HintBoardView.swift
//  Sudoku
//

import SwiftUI

struct HintBoardView: View {
    let puzzle: Puzzle
    let hint: HintResult
    let highlightedDigit: Int?
    
    @Environment(\.customAccentColor) private var accentColor
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<Puzzle.size, id: \.self) { row in
                GridRow {
                    ForEach(0..<Puzzle.size, id: \.self) { col in
                        Rectangle()
                            .fill(highlight(forRow: row, col: col).color(accent: accentColor))
                            .aspectRatio(1.0, contentMode: .fit)
                            .border(.gray.opacity(0.6), width: 0.5)
                            .overlay {
                                CellView(
                                    cell: puzzle.cells[row][col],
                                    highlightedDigit: highlightedDigit
                                )
                            }
                    }
                }
            }
        }
        .overlay {
            BlockGridOverlayView()
                .allowsHitTesting(false)
        }
    }
    
    private func highlight(forRow row: Int, col: Int) -> CellHighlight {
        if hint.primaryCells.contains(where: { $0.row == row && $0.col == col }) {
            return .hintPrimary
        }
        if hint.secondaryCells.contains(where: { $0.row == row && $0.col == col }) {
            return .hintSecondary
        }
        return .none
    }
}
