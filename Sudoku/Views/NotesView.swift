//
//  NotesView.swift
//  Sudoku
//

import SwiftUI

/// Displays the notes of a cell as a 3×3 mini-grid of small digits.
struct NotesView: View {
    let notes: Set<Int>
    let highlightedDigit: Int?
    var invalidNotes: Set<Int> = []
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<Puzzle.blockSize, id: \.self) { row in
                GridRow {
                    ForEach(0..<Puzzle.blockSize, id: \.self) { col in
                        let number = row * Puzzle.blockSize + col + 1
                        let isPresent = notes.contains(number)
                        let isInvalid = isPresent && invalidNotes.contains(number)
                        let isHighlighted = highlightedDigit == number && isPresent
                        Text(isPresent ? "\(number)" : " ")
                            .font(fontOption.font(size: Style.noteFontSize))
                            .minimumScaleFactor(0.01)
                            .lineLimit(1)
                            .fontWeight(isHighlighted ? .bold : .regular)
                            .foregroundStyle(
                                isHighlighted
                                ? accentColor
                                : Color.secondary
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay {
                                if isInvalid {
                                    GeometryReader { geo in
                                        Path { path in
                                            let y = geo.size.height / 2
                                            path.move(to: CGPoint(x: 0, y: y))
                                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                        }
                                        .stroke(Color.primary.opacity(0.5), lineWidth: 1.5)
                                    }
                                }
                            }
                            .background(
                                isHighlighted
                                ? accentColor.opacity(Style.highlightOpacity)
                                : Color.clear
                            )
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
