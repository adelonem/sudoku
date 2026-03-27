//
//  KeyboardActionButton.swift
//  sudoku
//

import SwiftUI

/// A reusable action button for the keyboard toolbar row.
struct KeyboardActionButton: View {
    let icon: String
    var isActive: Bool = false
    let tint: Color
    var aspectRatio: CGFloat = 1.0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.callout)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: Style.keyCornerRadius)
                        .fill(tint.opacity(isActive ? Style.highlightOpacity : Style.inactiveBackgroundOpacity))
                )
        }
        .buttonStyle(.plain)
    }
}
