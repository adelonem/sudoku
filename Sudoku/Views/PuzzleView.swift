//
//  PuzzleView.swift
//  Sudoku
//

import SwiftUI

struct PuzzleView: View {
    var viewModel: PuzzleViewModel
    @Environment(\.customAccentColor) private var accentColor
    @State private var longPressRow: Int?
    @State private var longPressCol: Int?
    @State private var longPressFilling = false
    
    private let longPressDuration = 1.0
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<Puzzle.size, id: \.self) { row in
                GridRow {
                    ForEach(0..<Puzzle.size, id: \.self) { col in
                        let cell = viewModel.cell(row: row, col: col)
                        let highlight = viewModel.highlight(row: row, col: col)
                        let invalid = viewModel.invalidNotes(row: row, col: col)
                        let conflict = viewModel.hasConflict(atRow: row, col: col)
                        let celebrationDelay = viewModel.celebrationDelay(row: row, col: col)
                        
                        Rectangle()
                            .fill(highlight.color(accent: accentColor))
                            .aspectRatio(1.0, contentMode: .fit)
                            .border(.gray.opacity(0.6), width: 0.5)
                            .overlay {
                                CellView(
                                    cell: cell,
                                    highlightedDigit: viewModel.highlightedDigit,
                                    invalidNotes: invalid,
                                    hasConflict: conflict
                                )
                            }
                            .overlay {
                                if longPressRow == row && longPressCol == col {
                                    Rectangle()
                                        .fill(Color.red.opacity(0.25))
                                        .scaleEffect(y: longPressFilling ? 1.0 : 0.0, anchor: .bottom)
                                        .allowsHitTesting(false)
                                }
                            }
                            .overlay {
                                CelebrationOverlay(
                                    color: accentColor,
                                    delay: celebrationDelay
                                )
                            }
                            .onLongPressGesture(minimumDuration: longPressDuration, pressing: { pressing in
                                if pressing {
                                    guard !cell.isFixed && cell != .empty else { return }
                                    longPressRow = row
                                    longPressCol = col
                                    longPressFilling = false
                                    withAnimation(.linear(duration: longPressDuration)) {
                                        longPressFilling = true
                                    }
                                } else {
                                    longPressFilling = false
                                    longPressRow = nil
                                    longPressCol = nil
                                }
                            }, perform: {
                                viewModel.select(row: row, col: col)
                                viewModel.deleteCell()
                            })
                            .gesture(TapGesture(count: 2).onEnded {
                                viewModel.select(row: row, col: col)
                                if let digit = viewModel.selectedDigit {
                                    viewModel.placeDigit(digit)
                                }
                            })
                            .simultaneousGesture(TapGesture().onEnded {
                                viewModel.select(row: row, col: col)
                                if let digit = viewModel.selectedDigit {
                                    viewModel.toggleNote(digit)
                                }
                            })
                    }
                }
            }
        }
        .overlay {
            BlockGridOverlayView()
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    let vm = PuzzleViewModel(puzzle: .sample)
    vm.select(row: 1, col: 1)
    return PuzzleView(viewModel: vm)
        .padding()
}
