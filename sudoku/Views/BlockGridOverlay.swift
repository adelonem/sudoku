//
//  BlockGridOverlay.swift
//  sudoku
//

import SwiftUI

/// Draws the thick 3×3 block borders over the puzzle grid.
struct BlockGridOverlay: View {
    private static let lineCount = Puzzle.blockSize + 1
    private static let lineWidth: CGFloat = 2
    
    var body: some View {
        Canvas { context, size in
            let step = size.width / CGFloat(Puzzle.blockSize)
            
            for i in 0..<Self.lineCount {
                let position = CGFloat(i) * step
                // Clamp to keep border lines within bounds
                let offset = min(position, size.width - Self.lineWidth)
                
                context.fill(
                    Path(CGRect(x: offset, y: 0, width: Self.lineWidth, height: size.height)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 0, y: offset, width: size.width, height: Self.lineWidth)),
                    with: .color(.primary)
                )
            }
        }
    }
}
