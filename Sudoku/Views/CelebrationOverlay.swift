//
//  CelebrationOverlay.swift
//  Sudoku
//

import SwiftUI

/// Animated overlay that briefly flashes the accent color on a cell when a zone is completed.
struct CelebrationOverlay: View {
    let color: Color
    let delay: Double?
    
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(isAnimating ? Style.highlightOpacity : 0))
            .allowsHitTesting(false)
            .onChange(of: delay) { oldValue, newValue in
                if let newValue {
                    isAnimating = false
                    withAnimation(.easeInOut(duration: 0.3).delay(newValue)) {
                        isAnimating = true
                    } completion: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAnimating = false
                        }
                    }
                } else {
                    isAnimating = false
                }
            }
    }
}
