//
//  KeyboardView.swift
//  sudoku
//

import SwiftUI

struct KeyboardView: View {
    let onNumber: (Int) -> Void
    let onNewGame: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<3) { i in
                GridRow {
                    ForEach(0..<3) { j in
                        let number = 3 * i + j + 1
                        Button {
                            onNumber(number)
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
                    onDelete()
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
                    onNewGame()
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
