//
//  FireworkParticle.swift
//  Sudoku
//

import SwiftUI

/// A single firework particle used in the celebration animation.
struct FireworkParticle: Identifiable {
    let id = UUID()
    var color: Color
    var startX: CGFloat
    var startY: CGFloat
    var endX: CGFloat
    var endY: CGFloat
    var scale: CGFloat
    var delay: Double
}
