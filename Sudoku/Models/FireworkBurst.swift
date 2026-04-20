//
//  FireworkBurst.swift
//  Sudoku
//

import SwiftUI

/// A burst of particles originating from a single point.
struct FireworkBurst: Identifiable {
    let id = UUID()
    let particles: [FireworkParticle]
    
    static func generate(in size: CGSize, count: Int = 5) -> [FireworkBurst] {
        let colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green, .cyan, .mint]
        return (0..<count).map { i in
            let centerX = CGFloat.random(in: size.width * 0.15...size.width * 0.85)
            let centerY = CGFloat.random(in: size.height * 0.1...size.height * 0.5)
            let burstColor = colors[i % colors.count]
            let particleCount = Int.random(in: 10...16)
            let particles = (0..<particleCount).map { _ in
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 40...120)
                return FireworkParticle(
                    color: burstColor,
                    startX: centerX,
                    startY: centerY,
                    endX: centerX + cos(angle) * distance,
                    endY: centerY + sin(angle) * distance,
                    scale: CGFloat.random(in: 0.4...1.0),
                    delay: Double(i) * 0.4 + Double.random(in: 0...0.15)
                )
            }
            return FireworkBurst(particles: particles)
        }
    }
}
