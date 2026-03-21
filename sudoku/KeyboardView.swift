//
//  KeyboardView.swift
//  sudoku
//

import SwiftUI

struct KeyboardView: View {
    let game: Game

    var body: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                GridRow {
                    ForEach(0..<3, id: \.self) { j in
                        let number = 3 * i + j + 1
                        Button {
                            game.setValue(number)
                        } label: {
                            Text("\(number)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1.0, contentMode: .fit)
                                .background(RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            GridRow {
                Button {
                    game.setValue(nil)
                } label: {
                    Image(systemName: "clear")
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.red.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Button {
                    game.newGame()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(2.0, contentMode: .fit)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .gridCellColumns(2)
            }
        }
    }
}
