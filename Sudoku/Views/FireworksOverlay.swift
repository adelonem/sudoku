//
//  FireworksOverlay.swift
//  Sudoku
//

import SwiftUI

/// Animates firework particles across the full screen.
struct FireworksOverlay: View {
    @State private var bursts: [FireworkBurst] = []
    @State private var animating = false
    @State private var round = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(bursts) { burst in
                    ForEach(burst.particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: 6 * particle.scale, height: 6 * particle.scale)
                            .shadow(color: particle.color.opacity(0.6), radius: 4)
                            .position(
                                x: animating ? particle.endX : particle.startX,
                                y: animating ? particle.endY : particle.startY
                            )
                            .opacity(animating ? 0 : 1)
                            .scaleEffect(animating ? 0.3 : 1.2)
                            .animation(
                                .easeOut(duration: 1.0).delay(particle.delay),
                                value: animating
                            )
                    }
                }
            }
            .onAppear {
                launchRound(in: geo.size)
            }
            .onChange(of: round) {
                launchRound(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func launchRound(in size: CGSize) {
        animating = false
        bursts = FireworkBurst.generate(in: size)
        withAnimation {
            animating = true
        }
        let roundDuration = 2.5
        DispatchQueue.main.asyncAfter(deadline: .now() + roundDuration) {
            round += 1
        }
    }
}
