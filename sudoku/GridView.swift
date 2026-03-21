//
//  GridView.swift
//  sudoku
//

import SwiftUI

struct GridView: View {
    let game: Game

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                GridRow {
                    ForEach(0..<9, id: \.self) { col in
                        Rectangle()
                            .fill(cellColor(row: row, col: col))
                            .aspectRatio(1.0, contentMode: .fit)
                            .border(.gray.opacity(0.6), width: 0.5)
                            .overlay {
                                if let digit = game.digit(atRow: row, col: col) {
                                    Text("\(digit)")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(
                                            game.isClue(atRow: row, col: col)
                                                ? Color.primary
                                                : Color.accentColor
                                        )
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
            Canvas { context, size in
                let step = size.width / 3
                let lineWidth: CGFloat = 2

                for i in 0...3 {
                    let offset = CGFloat(i) * step - (i > 2 ? 2 : i > 0 ? 1 : 0)
                    context.fill(
                        Path(CGRect(x: offset, y: 0, width: lineWidth, height: size.height)),
                        with: .color(.primary)
                    )
                    context.fill(
                        Path(CGRect(x: 0, y: offset, width: size.width, height: lineWidth)),
                        with: .color(.primary)
                    )
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func cellColor(row: Int, col: Int) -> Color {
        guard let selected = game.selectedCell else { return Color(nsColor: .textBackgroundColor) }

        // Highlight the selected cell
        if selected.row == row && selected.col == col {
            return Color.accentColor.opacity(0.3)
        }

        // Highlight cells with the same digit as the selected cell
        let selectedDigit = game.digit(atRow: selected.row, col: selected.col)
        let digit = game.digit(atRow: row, col: col)
        if let selectedDigit, let digit, selectedDigit == digit {
            return Color.accentColor.opacity(0.3)
        }

        // Highlight cells in the same row, column, or 3x3 block
        if selected.row == row
            || selected.col == col
            || (selected.row / 3 == row / 3 && selected.col / 3 == col / 3) {
            return Color.accentColor.opacity(0.1)
        }

        return Color(nsColor: .textBackgroundColor)
    }
}
