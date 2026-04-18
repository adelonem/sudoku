//
//  CalloutBubble.swift
//  Sudoku
//

import SwiftUI

struct CalloutBubble: Shape {
    let arrowAtBottom: Bool
    let arrowRatio: CGFloat
    let cornerRadius: CGFloat
    let arrowWidth: CGFloat
    let arrowHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let bubbleRect: CGRect
        if arrowAtBottom {
            bubbleRect = CGRect(x: rect.minX, y: rect.minY,
                                width: rect.width, height: rect.height - arrowHeight)
        } else {
            bubbleRect = CGRect(x: rect.minX, y: rect.minY + arrowHeight,
                                width: rect.width, height: rect.height - arrowHeight)
        }
        
        var path = Path(roundedRect: bubbleRect, cornerRadius: cornerRadius)
        
        let rawTipX = rect.minX + arrowRatio * rect.width
        let tipLo   = rect.minX + cornerRadius + arrowWidth / 2
        let tipHi   = rect.maxX - cornerRadius - arrowWidth / 2
        let tipX    = min(max(rawTipX, tipLo), tipHi)
        
        var arrow = Path()
        if arrowAtBottom {
            arrow.move(to: CGPoint(x: tipX - arrowWidth / 2, y: bubbleRect.maxY))
            arrow.addLine(to: CGPoint(x: tipX,               y: rect.maxY))
            arrow.addLine(to: CGPoint(x: tipX + arrowWidth / 2, y: bubbleRect.maxY))
        } else {
            arrow.move(to: CGPoint(x: tipX - arrowWidth / 2, y: bubbleRect.minY))
            arrow.addLine(to: CGPoint(x: tipX,               y: rect.minY))
            arrow.addLine(to: CGPoint(x: tipX + arrowWidth / 2, y: bubbleRect.minY))
        }
        arrow.closeSubpath()
        path.addPath(arrow)
        
        return path
    }
}
