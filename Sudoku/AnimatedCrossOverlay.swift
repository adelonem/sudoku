//
//  AnimatedCrossOverlay.swift
//  Sudoku
//

import SwiftUI

/// Animated cross that appears large then shrinks to its final size.
struct AnimatedCrossOverlay: View {
    @State private var scale: CGFloat = 1.8
    
    var body: some View {
        CrossShape()
            .stroke(Color.primary.opacity(0.6), lineWidth: 2)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                    scale = 1.0
                }
            }
    }
}
