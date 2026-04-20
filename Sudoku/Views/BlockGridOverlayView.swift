//
//  BlockGridOverlayView.swift
//  Sudoku
//

import SwiftUI

/// Draws the thick 3×3 block borders over the puzzle grid.
struct BlockGridOverlayView: View {
    private static let lineCount = Puzzle.blockSize + 1
    
    var body: some View {
        Canvas { context, size in
            let step = size.width / CGFloat(Puzzle.blockSize)
            
            for i in 0..<Self.lineCount {
                let position = CGFloat(i) * step
                let offset = min(position, size.width - 2)
                
                context.fill(
                    Path(CGRect(x: offset, y: 0, width: 2, height: size.height)),
                    with: .color(.primary)
                )
                context.fill(
                    Path(CGRect(x: 0, y: offset, width: size.width, height: 2)),
                    with: .color(.primary)
                )
            }
        }
    }
}
