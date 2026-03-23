//
//  PuzzleGridCell.swift
//  sudoku
//

import SwiftUI

/// Displays the notes of a cell as a 3×3 mini-grid of small digits.
struct PuzzleGridCell: View {
    let notes: Set<Int>
    let highlightedDigit: Int?
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<Puzzle.blockSize, id: \.self) { row in
                GridRow {
                    ForEach(0..<Puzzle.blockSize, id: \.self) { col in
                        let number = row * Puzzle.blockSize + col + 1
                        Text(notes.contains(number) ? "\(number)" : " ")
                            .font(.caption2)
                            .fontWeight(highlightedDigit == number ? .bold : .regular)
                            .foregroundStyle(
                                highlightedDigit == number
                                ? Color.accentColor
                                : Color.secondary
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
