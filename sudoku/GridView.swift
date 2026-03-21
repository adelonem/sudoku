//
//  GridView.swift
//  sudoku
//

import SwiftUI

struct GridView: View {
    @Binding var selectedRow: Int?
    @Binding var selectedCol: Int?
    let values: [Int?]

    private func cellColor(row: Int, col: Int) -> Color {
        guard let selectedRow, let selectedCol else {
            return Color(nsColor: .textBackgroundColor)
        }
        
        // Highlight the selected cell
        if selectedRow == row && selectedCol == col {
            return Color.accentColor.opacity(0.3)
        }
        
        // Highlight cells with the same digit as the selected cell
        let selectedValue = cellValue(row: selectedRow, col: selectedCol)
        let value = cellValue(row: row, col: col)
        if let selectedValue, let value, selectedValue == value {
            return Color.accentColor.opacity(0.3)
        }
        
        // Highlight cells in the same row
        if selectedRow == row {
            return Color.accentColor.opacity(0.1)
        }
        
        // Highlight cells in the same column
        if selectedCol == col {
            return Color.accentColor.opacity(0.1)
        }
        
        // Highlight cells in the same 3x3 block
        if selectedRow / 3 == row / 3 && selectedCol / 3 == col / 3 {
            return Color.accentColor.opacity(0.1)
        }
        
        return Color(nsColor: .textBackgroundColor)
    }

    private func cellValue(row: Int, col: Int) -> Int? {
        guard let value = values[9 * row + col] else {
            return nil
        }
        
        return value % 10
    }

    private func isInitialValue(row: Int, col: Int) -> Bool {
        guard let value = values[9 * row + col] else {
            return false
        }
        
        return value > 10
    }
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<9) { row in
                GridRow {
                    ForEach(0..<9) { col in
                        Rectangle()
                            .fill(cellColor(row: row, col: col))
                            .aspectRatio(1.0, contentMode: .fit)
                            .border(.gray.opacity(0.6), width: 0.5)
                            .overlay {
                                if let value = cellValue(row: row, col: col) {
                                    Text("\(value)")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(
                                            isInitialValue(row: row, col: col)
                                                ? Color.primary
                                                : Color.accentColor
                                        )
                                }
                            }
                            .onTapGesture {
                                selectedRow = row
                                selectedCol = col
                            }
                    }
                }
            }
        }
        .overlay {
            Canvas { context, size in
                let step = size.width / 3
                
                // Horizontal lines
                context.fill(
                    Path(CGRect(x: 0, y: 0, width: size.width, height: 2)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 0, y: step - 1, width: size.width, height: 2)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 0, y: 2 * step - 1, width: size.width, height: 2)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 0, y: 3 * step - 2, width: size.width, height: 2)),
                    with: .color(.primary)
                )
                
                // Vertical lines
                context.fill(
                    Path(CGRect(x: 0, y: 0, width: 2, height: size.height)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: step - 1, y: 0, width: 2, height: size.height)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 2 * step - 1, y: 0, width: 2, height: size.height)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 3 * step - 2, y: 0, width: 2, height: size.height)),
                    with: .color(.primary)
                )
            }
            .allowsHitTesting(false)
        }
    }
}
