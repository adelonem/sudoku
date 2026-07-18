//
//  HintChainArrowsView.swift
//  Sudoku
//

import SwiftUI

/// Draws directional arrows over the puzzle grid to show how to read the sequence of
/// cells forming a chain-based hint (forcing chains, skyscraper, coloring, AIC).
/// The overlay expects to occupy the exact square footprint of the 9×9 grid.
struct HintChainArrowsView: View {
    /// Ordered cells of the chain. Arrows connect each cell to the next.
    let chain: [(row: Int, col: Int)]
    /// Stroke color of the arrows, drawn over a light halo for contrast.
    var color: Color = .orange

    /// Contrasting outline drawn under the arrows so they stay legible over the
    /// amber hint highlights and white cells alike.
    private let halo: Color = .white

    var body: some View {
        Canvas { context, size in
            guard chain.count >= 2 else { return }

            let cell = size.width / CGFloat(Puzzle.size)
            let inset = cell * 0.30
            let arrowLength = cell * 0.24
            let spread = CGFloat.pi / 7

            func center(_ cellPos: (row: Int, col: Int)) -> CGPoint {
                CGPoint(
                    x: (CGFloat(cellPos.col) + 0.5) * cell,
                    y: (CGFloat(cellPos.row) + 0.5) * cell
                )
            }

            // Mark the starting cell with a small ring so the reading order is unambiguous.
            let origin = center(chain[0])
            let ringRadius = cell * 0.18
            let ring = Path(ellipseIn: CGRect(
                x: origin.x - ringRadius, y: origin.y - ringRadius,
                width: ringRadius * 2, height: ringRadius * 2
            ))
            context.stroke(ring, with: .color(halo), style: StrokeStyle(lineWidth: 4))
            context.stroke(ring, with: .color(color), style: StrokeStyle(lineWidth: 2))

            for index in 0..<(chain.count - 1) {
                let from = center(chain[index])
                let to = center(chain[index + 1])

                let dx = to.x - from.x
                let dy = to.y - from.y
                let distance = hypot(dx, dy)
                guard distance > 0 else { continue }

                let ux = dx / distance
                let uy = dy / distance
                let start = CGPoint(x: from.x + ux * inset, y: from.y + uy * inset)
                let end = CGPoint(x: to.x - ux * inset, y: to.y - uy * inset)

                var line = Path()
                line.move(to: start)
                line.addLine(to: end)

                var head = Path()
                let angle = atan2(uy, ux)
                let left = CGPoint(
                    x: end.x - arrowLength * cos(angle - spread),
                    y: end.y - arrowLength * sin(angle - spread)
                )
                let right = CGPoint(
                    x: end.x - arrowLength * cos(angle + spread),
                    y: end.y - arrowLength * sin(angle + spread)
                )
                head.move(to: end)
                head.addLine(to: left)
                head.addLine(to: right)
                head.closeSubpath()

                // Halo first, then the colored arrow on top.
                context.stroke(line, with: .color(halo), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                context.stroke(head, with: .color(halo), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
                context.fill(head, with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.orange.opacity(0.2)
        HintChainArrowsView(
            chain: [(0, 0), (0, 4), (3, 4), (3, 7), (8, 7)],
            color: .blue
        )
    }
    .frame(width: 300, height: 300)
}
